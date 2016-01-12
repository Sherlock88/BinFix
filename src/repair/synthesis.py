import os
import subprocess
from utils import cd
import logging
import json
from pprint import pprint
import tempfile
import shutil
from os.path import join


logger = logging.getLogger(__name__)


class Synthesizer:

    def __init__(self, working_dir, config, extracted, angelic_forest_file):
        self.working_dir = working_dir
        self.config = config
        self.extracted = extracted
        self.angelic_forest_file = angelic_forest_file

    def dump_angelic_forest(self, angelic_forest):
        '''
        Convert angelic forest to format more suitable for current synthesis engine
        '''
        def id(expr):
            return '{}-{}-{}-{}'.format(*expr)

        dumpable_angelic_forest = dict()
        for test, paths in angelic_forest.items():
            dumpable_paths = []
            for path in paths:
                dumpable_path = []

                for expr, values in path.items():
                    for instance, value in enumerate(values):
                        angelic, _, environment = value  # ignore original for now
                        context = []
                        for name, value in environment.items():
                            context.append({'name': name,
                                            'value': value})
                        dumpable_path.append({ 'context': context,
                                               'value': { 'name': 'angelic',
                                                          'value': angelic },
                                               'expression': id(expr),
                                               'instId': instance })
                dumpable_paths.append(dumpable_path)
            dumpable_angelic_forest[test] = dumpable_paths

        with open(self.angelic_forest_file, 'w') as file:
            json.dump(dumpable_angelic_forest, file, indent=2)

    def __call__(self, angelic_forest):

        if type(angelic_forest) == str:
            # angelic_forest is a file
            shutil.copyfile(angelic_forest, self.angelic_forest_file)
        else:
            # angelic_forest is a data structure
            self.dump_angelic_forest(angelic_forest)

        dirpath = tempfile.mkdtemp()
        patch_file = join(dirpath, 'patch')
        config_file = join(dirpath, 'config.json')

        for level in self.config['synthesis_levels']:

            logger.info('synthesizing patch with component level \'{}\''.format(level))

            # prepare default extracted files
            with open(self.angelic_forest_file, 'r') as file:
                af = json.load(file)
            for test_id in af:
                for inst in af[test_id]:
                    for loc in inst:
                        exp_id = loc["expression"]
                        def_exp_file = join(self.working_dir, 
                                            "extracted", exp_id + ".smt2")
                        with open(def_exp_file, "w") as file:
                            file.write("(assert true)") # default contents

            config = {
                "encodingConfig": {
                    "componentsMultipleOccurrences": True,
                    # better if false, if not enough primitive components, synthesis can fail
                    "phantomComponents": True,
                    "repairBooleanConst": False,
                    "repairIntegerConst": False,
                    "level": "linear"
                },
                "simplification": False,
                "reuseStructure": not self.config['semfix'],
                "spaceReduction": True,
                "componentLevel": level,
                "solverBound": 3,
                "solverTimeout": self.config['synthesis_timeout']
            }

            with open(config_file, 'w') as file:
                json.dump(config, file)

            jar = os.environ['SYNTHESIS_JAR']

            if self.config['verbose']:
                stderr = None
            else:
                stderr = subprocess.DEVNULL

            args = [self.angelic_forest_file, self.extracted, patch_file, config_file]

            try:
                result = subprocess.check_output(['java', '-jar', jar] + args, stderr=stderr)
            except subprocess.CalledProcessError:
                logger.warning("synthesis returned non-zero code")
                continue

            if str(result, 'UTF-8').strip() == 'TIMEOUT':
                logger.warning('timeout when synthesizing fix')
            elif str(result, 'UTF-8').strip() == 'FAIL':
                logger.info('synthesis failed')
            elif str(result, 'UTF-8').strip() == 'SUCCESS':
                logger.info('created patch file: {}'.format(patch_file))
                with open(patch_file) as file:
                    content = file.readlines()
                patch = dict()
                while len(content) > 0:
                    line = content.pop(0)
                    if len(line) == 0:
                        continue
                    expr = tuple(map(int, line.strip().split('-')))
                    original = content.pop(0).strip()
                    fixed = content.pop(0).strip()
                    if self.config['semfix']:
                        logger.info('synthesized expression {}: {}'.format(expr, fixed))
                    else:
                        logger.info('fixing expression {}: {} ---> {}'.format(expr, original, fixed))
                    patch[expr] = fixed
                return patch
            else:
                raise Exception('result: ' + str(result, 'UTF-8'))

        shutil.rmtree(dirpath)

        return None
