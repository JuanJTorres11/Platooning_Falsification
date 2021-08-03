"""
Framework for experimentation of parallel and multi-objective falsification.

Author: Kesav Viswanadha
Email: kesav@berkeley.edu
"""

import time
import os
import numpy as np
from dotmap import DotMap
import traceback
import argparse

from verifai.samplers.scenic_sampler import ScenicSampler
from verifai.scenic_server import ScenicServer
from verifai.falsifier import generic_falsifier, generic_parallel_falsifier
from verifai.monitor import multi_objective_monitor, specification_monitor
from verifai.falsifier import generic_falsifier
import networkx as nx
import pandas as pd


def announce(message):
    lines = message.split('\n')
    size = max([len(p) for p in lines]) + 4

    def pad(line):
        ret = '* ' + line
        ret += ' ' * (size - len(ret) - 1) + '*'
        return ret
    lines = list(map(pad, lines))
    m = '\n'.join(lines)
    border = '*' * size
    print(border)
    print(m)
    print(border)


"""
Single-objective specification. This monitor is similar to the one above, but takes a
minimum over the distances from each vehicle. If the ego vehicle is less than 5 meters
away from any vehicle at any point, a counterexample is returned.
"""


class distance(specification_monitor):
    def __init__(self):
        def specification(simulation):
            positions = np.array(simulation.result.trajectory)
            """
            print("positions:")
            print(positions)
            distances1 = positions[:, [1], :] - positions[:, 2:, :]
            print("distances1:")
            print(distances1)
            distances2 = positions[:, [2], :] - positions[:, [3], :]
            print("distances2:")
            print(distances2)
            distances1 = np.linalg.norm(distances1, axis=2)
            distances2 = np.linalg.norm(distances2, axis=2)
            rho1 = np.min(distances1) - 5
            rho2 = np.min(distances2) - 5
            return min(rho1, rho2)
            """
            distances = positions[:, [1], :] - positions[:, 2:, :]
            distances = np.linalg.norm(distances, axis=2)
            rho = np.min(distances) - 5
            return rho


        super().__init__(specification)


"""
Runs all experiments in a directory.
"""


def run_experiments(path, parallel=False, model=None,
                    sampler_type=None, headless=False, num_workers=5, output_dir='outputs',
                    experiment_name=None, map_path=None, lgsvl=False):
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
    paths = []
    if os.path.isdir(path):
        for root, _, files in os.walk(path):
            for name in files:
                fname = os.path.join(root, name)
                if os.path.splitext(fname)[1] == '.scenic':
                    paths.append(fname)
    else:
        paths = [path]
    for p in paths:
        try:
            falsifier = run_experiment(p, parallel=parallel,
                                       model=model, sampler_type=sampler_type, headless=headless,
                                       num_workers=num_workers)
        except:
            announce(f'ERROR FOR SCRIPT {p}:\n\n{traceback.format_exc()}')
            continue
        df = pd.concat([falsifier.error_table.table,
                        falsifier.safe_table.table])
        if experiment_name is not None:
            outfile = experiment_name
        else:
            root, _ = os.path.splitext(p)
            outfile = root.split('/')[-1]
            if parallel:
                outfile += '_parallel'
            if model:
                outfile += f'_{model}'
            if sampler_type:
                outfile += f'_{sampler_type}'
        outfile += '.csv'
        outpath = os.path.join(output_dir, outfile)
        announce(f'SAVING OUTPUT TO {outpath}')
        df.to_csv(outpath)


"""
Runs a single falsification experiment.

Arguments:
    path: Path to Scenic script to be run.
    parallel: Whether or not to enable parallelism.
    model: Which simulator model to use (e.g. carla, lgsvl, newtonian, etc.)
    sampler_type: Which VerifAI sampelr to use (e.g. halton, scenic, ce, mab, etc.)
    headless: Whether or not to display each simulation.
    num_workers: Number of parallel workers. Only used if parallel is true.
"""


def run_experiment(path, parallel=False, model=None,
                   sampler_type=None, headless=False, num_workers=5):
    announce(f'RUNNING SCENIC SCRIPT {path}')
    model = f'scenic.simulators.{model}.model' if model else None
    params = {'verifaiSamplerType': sampler_type} if sampler_type else {}
    params['render'] = not headless
    if model:
        params['model'] = model
    sampler = ScenicSampler.fromScenario(path, **params)
    falsifier_params = DotMap(
        n_iters=None,
        save_error_table=True,
        save_safe_table=True,
        max_time=1800,
    )
    server_options = DotMap(maxSteps=300, verbosity=0)
    monitor = distance()

    falsifier_cls = generic_parallel_falsifier if parallel else generic_falsifier

    falsifier = falsifier_cls(sampler=sampler, falsifier_params=falsifier_params,
                              server_class=ScenicServer,
                              server_options=server_options,
                              monitor=monitor, scenic_path=path,
                              scenario_params=params, num_workers=num_workers)
    t0 = time.time()
    print('Running falsifier')
    falsifier.run_falsifier()
    t = time.time() - t0
    print()
    print(
        f'Generated {len(falsifier.samples)} samples in {t} seconds with {falsifier.num_workers} workers')
    print(f'Number of counterexamples: {len(falsifier.error_table.table)}')
    if not parallel:
        print(f'Sampling time: {falsifier.total_sample_time}')
        print(f'Simulation time: {falsifier.total_simulate_time}')
    print(f'Confidence interval: {falsifier.get_confidence_interval()}')

    return falsifier


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--path', '-p', type=str, default='platoon.scenic',
                        help='Path to Scenic script')
    parser.add_argument('--parallel', action='store_true')
    parser.add_argument('--num-workers', type=int, default=5,
                        help='Number of parallel workers')
    parser.add_argument('--sampler-type', '-s', type=str, default=None,
                        help='verifaiSamplerType to use')
    parser.add_argument('--experiment-name', '-e', type=str, default=None,
                        help='verifaiSamplerType to use')
    parser.add_argument('--model', '-m', type=str, default=None)
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--lgsvl', '-l', action='store_true')
    args = parser.parse_args()
    run_experiments(args.path, args.parallel,
                    model=args.model, sampler_type=args.sampler_type, headless=args.headless,
                    num_workers=args.num_workers, experiment_name=args.experiment_name, lgsvl=args.lgsvl)
