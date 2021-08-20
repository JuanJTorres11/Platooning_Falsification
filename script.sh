#! /bin/bash

python3.8 attack_1_bo/falsifier.py --model lgsvl
python3.8 attack_1_ce/falsifier.py --model lgsvl
python3.8 attack_2_bo/falsifier.py --model lgsv
python3.8 attack_2_ce/falsifier.py --model lgsvl
python3.8 attack_3_bo/falsifier.py --model lgsvl
python3.8 attack_3_ce/falsifier.py --model lgsvl
python3.8 attack_4_bo/falsifier.py --model lgsvl
python3.8 attack_4_ce/falsifier.py --model lgsvl
