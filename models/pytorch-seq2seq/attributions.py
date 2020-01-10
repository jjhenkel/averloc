import os
import argparse
import torch
import torch.nn as nn
import torch.backends as backends
from torch.optim.lr_scheduler import StepLR
import torchtext

import seq2seq
from seq2seq.trainer import SupervisedTrainer
from seq2seq.models import EncoderRNN, DecoderRNN, Seq2seq
from seq2seq.loss import Perplexity
from seq2seq.optim import Optimizer
from seq2seq.dataset import TargetField
from seq2seq.util.checkpoint import Checkpoint

import numpy as np
import matplotlib.pyplot as plt
import matplotlib

device = 'cuda' if torch.cuda.is_available() else 'cpu'

# python attributions.py --expt_dir experiment/2020_01_07_11_15_29 --load_checkpoint 4_8769 --attr_type attention --src_seq "the british government is doing a good job" --verbose --output_fig_path example.png


def separator():
    print('-'*100)

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--expt_dir', action='store', dest='expt_dir', required=True)
    parser.add_argument('--load_checkpoint', action='store', dest='load_checkpoint', required=True)
    parser.add_argument('--src_seq', action='store', dest='src_seq', required=True)
    parser.add_argument('--attr_type', action='store', dest='attr_type', required=True, choices=['IG', 'attention'])
    parser.add_argument('--no_display', action='store_true', default=False)
    parser.add_argument('--output_fig_path', help='path to output figure', default=None)                     
    parser.add_argument('--verbose', action='store_true', default=False)
    parser.add_argument('--fig_title', default=None)
    parser.add_argument('--fig_size', nargs='+', help='Size of figure to be plotted', default=(10,6))
    opt = parser.parse_args()
    return opt


def load_model(opt):
    checkpoint_path = os.path.join(opt.expt_dir, Checkpoint.CHECKPOINT_DIR_NAME, opt.load_checkpoint)
    checkpoint = Checkpoint.load(checkpoint_path)
    model = checkpoint.model
    src_vocab = checkpoint.input_vocab
    tgt_vocab = checkpoint.output_vocab
    if opt.verbose:
        print('Loaded model')
    
#     model.eval()
    return model, src_vocab, tgt_vocab


def get_model_output(src_seq, model, src_vocab, tgt_vocab):
    '''
    returns output of model for a single input data point
    src_seq is a list of words
    '''
    src_id_seq = torch.LongTensor([src_vocab.stoi[tok] for tok in src_seq]).view(1, -1)
    if torch.cuda.is_available():
        src_id_seq = src_id_seq.cuda()

    softmax_list, _, decoder_features = model(src_id_seq, [len(src_seq)])
    length = decoder_features['length'][0]
    output_id_seq = [decoder_features['sequence'][di][0].data[0] for di in range(length)]
    output_seq = [tgt_vocab.itos[tok] for tok in output_id_seq]
    return softmax_list, decoder_features, output_id_seq, output_seq


def get_attention_attributions(opt, src_seq, model, src_vocab, tgt_vocab):
    '''
    model object returned by load_model
    src_seq is a list of words
    '''
    softmax_list, decoder_features, output_id_seq, output_seq = get_model_output(src_seq, model, src_vocab, tgt_vocab)
    attention_scores = torch.cat(decoder_features['attention_score']).cpu().detach().numpy().squeeze()
    attention_scores = attention_scores[:len(output_seq),:]
    return output_seq, attention_scores


def get_IG_attributions(opt, src_seq, model, src_vocab, tgt_vocab):
    '''
    model object returned by load_model
    src_seq is a list of words
    '''
    
    softmax_list, decoder_features, final_output_id_seq, final_output_seq = get_model_output(src_seq, model, src_vocab, tgt_vocab)
            
    # get embeddings of the src_seq
    src_id_seq = torch.LongTensor([src_vocab.stoi[tok] for tok in src_seq]).view(1, -1)
    if torch.cuda.is_available():
        src_id_seq = src_id_seq.cuda()
    embedded = model.encoder.embedding(src_id_seq)
    np_embed = embedded.clone().detach().cpu().numpy().squeeze()
    
    # baseline x' = embedding of all zeros
    baseline = np.zeros(np_embed.shape)
    
    # set number of steps in IG approximation (S from formula in original paper)
    NUM_STEPS = 300
    N = NUM_STEPS + 1

    l = []
    for i in range(N):
        l.append(baseline + (i/NUM_STEPS)*(np_embed-baseline))

    IG_inputs = torch.tensor(np.array(l),dtype=torch.float32,device=device)
    print(IG_inputs.size(), np_embed.shape, N)
    lengths = [np_embed.shape[0]]*N
    
    # To ensure correct IG, need to do teacher forcing when getting output from decoder
    # target_variable is used to do teacher forcing
    # Append Start of Sentence symbol in order to stagger output in the decoder
    target_variable = torch.stack([torch.LongTensor([tgt_vocab.stoi[TargetField.SYM_SOS]]).to(device)[0]]+final_output_id_seq[:-1])
    target_variable = target_variable.expand(N,len(final_output_id_seq))
        
    # reset model gradients
    model.zero_grad()

    softmax_list, _, decoder_features = model(input_variable=src_id_seq, input_lengths=lengths, target_variable=target_variable, teacher_forcing_ratio=1.0, embedded=IG_inputs)
    
    if opt.verbose:
        separator()
        print('Progression of IG outputs:')
        for i in range(0,N,25):
            length = decoder_features['length'][i]
            output_id_seq = [decoder_features['sequence'][di][i].data[0] for di in range(length)]
            output_seq = [tgt_vocab.itos[tok] for tok in output_id_seq]
            print(i, ' '.join(output_seq))
            
    length = decoder_features['length'][N-1]
    output_id_seq = [decoder_features['sequence'][di][N-1].data[0] for di in range(length)]
    output_seq = [tgt_vocab.itos[tok] for tok in output_id_seq] 
    
#     print(final_output_seq, output_seq)
    
    assert final_output_seq[:-1] == output_seq, 'Something wrong'
    output_len = len(output_seq)
    input_len = src_id_seq.size(1)


    IG_diff = IG_inputs[-1] - IG_inputs[0]

    l = []
    ones = torch.ones(softmax_list[0][:,0].size(), device='cuda')
    for i in range(output_len):
        model.zero_grad()
        t = softmax_list[i] # N x V+1
        
        # Reset gradient to zero
        if model.encoder.embedded[0].grad is not None:
            model.encoder.embedded[0].grad.data.zero_() 

        assert final_output_id_seq[i]==t[-1,:].max(0)[1], "Something wrong"
        t = t[:,final_output_id_seq[i]] # Size N
        
        # necessary to prevent: RuntimeError: cudnn RNN backward can only be called in training mode
        with backends.cudnn.flags(enabled=False):
            model.encoder.embedded[0].retain_grad()        
            t.backward(gradient=ones, retain_graph=True)
            g = model.encoder.embedded[0].grad
            g2 = g.view(input_len,N,-1)
            g3 = torch.mean(g2,axis=1)
            g4 = g3*IG_diff
            g5 = torch.sum(g4, axis=1)
            l.append(g5)

    attr = torch.stack(l).cpu().detach().numpy()
    
    # Verifying the completeness axiom
    attr_sums = attr.sum(axis=1)
    
    if opt.verbose:
        separator()
        print('Verifying IG attributions using completeness axiom...')
        print("Word             Actual difference     Predicted difference")
    for i in range(output_len):
        base = softmax_list[i][0][final_output_id_seq[i]]
        full = softmax_list[i][-1][final_output_id_seq[i]]
        actual_diff = full-base
        predicted_diff = attr_sums[i]
        assert abs(actual_diff-predicted_diff)<0.1, "Diverging from completeness axiom, consider increasing number of steps in IG"
        
        if opt.verbose:
            word = output_seq[i] + " "*(15-len(output_seq[i]))
            print(word,"\t",(full-base).cpu().detach().numpy(), "\t", attr_sums[i])
    
    
    return output_seq, attr


def plot_attributions(opt, attr, input_seq, output_seq):
    '''
    attr is a numpy array of size (len(output_seq), len(input_sequence))
    input_seq and output_seq are lists of strings
    '''
    assert attr.shape[0]==len(output_seq), "Mismatch in size of attributions and output_seq length"
    assert attr.shape[1]==len(input_seq), "Mismatch in size of attributions and input_seq length"
    
    plt.ioff()
    fig = plt.figure(figsize = opt.fig_size)
    plt.imshow(attr, aspect='auto')
    plt.xticks(np.arange(len(input_seq)), input_seq)
    plt.yticks(np.arange(len(output_seq)), output_seq)
    
    title = opt.fig_title if opt.fig_title else "Attribution Visualization: " + opt.attr_type
    plt.title(title)
    
    if opt.output_fig_path:
        plt.savefig(opt.output_fig_path)
        separator()
        print('Saved figure',opt.output_fig_path)
            
    if opt.no_display:
        plt.close(fig)
    else:
        plt.show()
    
    
def main(opt):
    model, src_vocab, tgt_vocab = load_model(opt)
    src_seq = opt.src_seq.lower().split(' ')
    
    if opt.verbose:
        print('Input sequence:', src_seq)
        print()
    
    if opt.attr_type=='attention':
        output_seq, scores = get_attention_attributions(opt, src_seq, model, src_vocab, tgt_vocab)
    elif opt.attr_type=='IG':
        output_seq, scores = get_IG_attributions(opt, src_seq, model, src_vocab, tgt_vocab)
        
    if opt.verbose:
        separator()
        print('Attribution matrix')
        print(scores)
        print()
    
    separator()
    print('Output:',' '.join(output_seq[:-1]))
    
    plot_attributions(opt, scores, src_seq, output_seq)
    

if __name__=="__main__":
    opt = parse_args()
    if opt.verbose:
        separator()
    main(opt)
    separator()
    
    
