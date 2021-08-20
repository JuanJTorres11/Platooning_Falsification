#! /bin/bash

cd attack_1_bo
python3.8 falsifier.py --model lgsvl
cd ..
cd attack_1_ce
python3.8 falsifier.py --model lgsvl
cd ..
cd attack_2_bo
python3.8 falsifier.py --model lgsv
cd ..
cd attack_2_ce
python3.8 falsifier.py --model lgsvl
cd .. 
cd attack_3_bo
python3.8 falsifier.py --model lgsvl
cd ..
cd attack_3_ce
python3.8 falsifier.py --model lgsvl
cd ..
cd attack_4_bo
python3.8 falsifier.py --model lgsvl
cd ..
cd attack_4_ce
python3.8 falsifier.py --model lgsvl
