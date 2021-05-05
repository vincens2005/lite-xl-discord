#!/usr/bin/python3
import argparse
import pickle
parser = argparse.ArgumentParser()
parser.add_argument("--text", dest="text")
args = parser.parse_args()

# communication setup:
fp = open("discord_data.pickle", "wb")
pickle.dump(args.text, fp,)
fp.close()
