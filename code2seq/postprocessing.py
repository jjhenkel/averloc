import os
from subprocess import call
import random
from math import ceil

def get_subdirs(a_dir, simple):
	subdirs = [name for name in os.listdir(a_dir) if os.path.isdir(os.path.join(a_dir, name))]
	return subdirs


def build_dict(a_dir):
	num_functions = 0
	function_dict = {}
	with open(a_dir+"/identity/data.train.c2s") as f:
		line = f.readline()
		while line:
			key = line.split(" ")[0]
			if not key in function_dict:
				function_dict[key] = num_functions
				num_functions += 1
			line = f.readline()

	with open(a_dir+"/function_dict",'w') as g:
		for key, val in function_dict.items():
			g.write(key+":"+str(val)+"\n")

	return function_dict

def build_adv_data(a_dir, dirs, function_dict):
	if not os.path.exists(a_dir+"/"+"adv_data"):
		call("mkdir "+a_dir+"/"+"adv_data", shell=True)
	dir_count = 0
	for d in dirs:
		if not os.path.exists(a_dir+"/"+"adv_data/"+str(dir_count)):
			call("mkdir "+a_dir+"/"+"adv_data/"+str(dir_count),shell=True)
		with open(a_dir+"/"+d+"/data.train.c2s") as f:
			line = f.readline()
			while line:
				key = line.split(" ")[0]
				if key in function_dict:
					num = function_dict[key]
				else:
					print(d + " has data non_exist, key is "+key +" the line is "+line)
					with open(a_dir+"/log", 'a+') as h:
						h.write(d + " has data non_exist, key is "+key +", the line is "+line+"\n")
				with open(a_dir+"/"+"adv_data/"+str(dir_count)+"/"+str(num)+".train.c2s",'a+') as g:
					g.write(line)
				line = f.readline()
		dir_count += 1
	print("num of transformations: "+ str(dir_count) +", num of functions: "+str(len(function_dict)))

def build_val_data(a_dir, dirs):
	open(a_dir+"/"+"data.val.c2s", 'w').close()
	ratio = 1.0/float(len(dirs))
	with open(a_dir+"/"+"data.val.c2s", 'a') as f:
		for d in dirs:
			lines = open(a_dir+"/"+d+"/data.val.c2s").readlines()
			num_lines = ceil(len(lines) * ratio)
			sampled_lines = random.sample(lines, num_lines)
			for line in sampled_lines:
				f.write(line)


subdirs = get_subdirs("data/transformed_data", True)
function_dict = build_dict("data/transformed_data")
build_adv_data("data/transformed_data", subdirs, function_dict)
call("cp identity/data.train.c2s data0.train.c2s", cwd="data/transformed_data", shell=True)
call("cp identity/data.dict.c2s .", cwd="data/transformed_data", shell=True)
build_val_data("data/transformed_data", subdirs)
