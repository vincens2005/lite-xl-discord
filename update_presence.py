#!/usr/bin/python3
import argparse
import pickle
import json
parser = argparse.ArgumentParser()
parser.add_argument("--state", dest="state")
parser.add_argument("--details", dest="details")
parser.add_argument("--die-now", dest="die_now")
parser.add_argument("--pickle", dest="pickle")
args = parser.parse_args()
# communication setup:
fp = open(args.pickle, "wb")
json_args = json.dumps({
  "state": args.state,
  "details": args.details,
  "die_now": args.die_now
})
pickle.dump(json_args, fp,)
fp.close()
