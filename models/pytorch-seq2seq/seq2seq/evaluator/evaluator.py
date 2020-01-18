from __future__ import print_function, division

import torch
import torchtext
from torch.nn.utils.rnn import pad_packed_sequence

import seq2seq
from seq2seq.loss import NLLLoss
from seq2seq.evaluator.metrics import calculate_metrics

import tqdm

class Evaluator(object):
    """ Class to evaluate models with given datasets.

    Args:
        loss (seq2seq.loss, optional): loss for evaluator (default: seq2seq.loss.NLLLoss)
        batch_size (int, optional): batch size for evaluator (default: 64)
    """

    def __init__(self, loss=NLLLoss(), batch_size=64):
        self.loss = loss
        self.batch_size = batch_size

    def evaluate(self, model, data, verbose=False):
        """ Evaluate a model on given dataset and return performance.

        Args:
            model (seq2seq.models): model to evaluate
            data (seq2seq.dataset.dataset.Dataset): dataset to evaluate against

        Returns:
            loss (float): loss of the given model on the given dataset
        """
        model.eval()

        loss = self.loss
        loss.reset()
        match = 0
        total = 0

        # device = None if torch.cuda.is_available() else -1
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        batch_iterator = torchtext.data.BucketIterator(
            dataset=data, batch_size=self.batch_size,
            sort=True, sort_key=lambda x: len(x.src),
            device=device, train=False)
        tgt_vocab = data.fields[seq2seq.tgt_field_name].vocab
        pad = tgt_vocab.stoi[data.fields[seq2seq.tgt_field_name].pad_token]
        eos = tgt_vocab.stoi[data.fields[seq2seq.tgt_field_name].SYM_EOS]

        output_seqs = []
        ground_truths = []

        with torch.no_grad():

            if verbose:
                batch_iterator = tqdm.tqdm(batch_iterator)

            for batch in batch_iterator:
                input_variables, input_lengths  = getattr(batch, seq2seq.src_field_name)
                target_variables = getattr(batch, seq2seq.tgt_field_name)

                decoder_outputs, decoder_hidden, other = model(input_variables, input_lengths.tolist(), target_variables)

                # decoder_outputs, decoder_hidden, other = model(input_variables, input_lengths.tolist())

                # print(target_variables, target_variables.size())
                # print(len(decoder_outputs), decoder_outputs[0].size())

                # Evaluation
                seqlist = other['sequence']
                for step, step_output in enumerate(decoder_outputs):
                    target = target_variables[:, step + 1]
                    loss.eval_batch(step_output.view(target_variables.size(0), -1), target)

                    non_padding = target.ne(pad)
                    non_eos = target.ne(eos)
                    mask = torch.mul(non_padding, non_eos)
                    # mask = non_padding 

                    correct = seqlist[step].view(-1).eq(target).masked_select(mask).sum().item()
                    match += correct
                    total += mask.sum().item()

                # print(other['length'])
                # print(other['sequence'])
                for i,output_seq_len in enumerate(other['length']):
                    # print(i,output_seq_len)
                    tgt_id_seq = [other['sequence'][di][i].data[0] for di in range(output_seq_len)]
                    tgt_seq = [tgt_vocab.itos[tok] for tok in tgt_id_seq]
                    # print(tgt_seq)
                    output_seqs.append(' '.join([x for x in tgt_seq if x not in ['<sos>','<eos>','<pad>']])) # exclude <eos> symbol
                    gt = [tgt_vocab.itos[tok] for tok in target_variables[i]]
                    ground_truths.append(' '.join([x for x in gt if x not in ['<sos>','<eos>','<pad>']]))

        # print(output_seqs)
        # print(ground_truths)
        # ground_truths = [' '.join(l[1:-1]) for l in data.tgt]
        # for i in range(len(ground_truths)):
            # print(ground_truths[i], " ---- ", output_seqs[i])
        # print([a for a in data.tgt])
        other_metrics = calculate_metrics(output_seqs, ground_truths)


        if total == 0:
            accuracy = float('nan')
        else:
            accuracy = match / total

        return loss.get_loss(), accuracy, other_metrics, (output_seqs, ground_truths)
