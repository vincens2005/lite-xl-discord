#!/usr/bin/python3
# you need to have pypresence installed for this to work
import time
import pickle
import os
from pypresence import Presence

discord_text = "nothing is happening"
waiting = False


def load_data(cur_txt):
    fp = open("discord_data.pickle", "rb")
    data = pickle.load(fp)
    if data == "die_now":
        exit()
    if data != cur_txt:
        print("got new data!")
        print(data)
        return data
    else:
        print("data is the same :(")
        print(data)
        return cur_txt


def reset_data():
    fp = open("discord_data.pickle", "wb")
    pickle.dump("loading discord plugin...", fp,)
    fp.close()


# discord client id:
client_id = "839231973289492541"
rpc = Presence(client_id)
print("connecting to rpc...")
rpc.connect()
start_time = time.time()
rpc.update(start=start_time, state="loading discord plugin", large_image="lite-xl")

reset_data()

while True:
    print("current discord text:", discord_text)
    discord_text = load_data(discord_text)
    rpc.update(
        pid=os.getpid(),
        start=start_time,
        state=discord_text,
        large_image="lite-xl"
    )
    time.sleep(15)  # discord sleep timeout
