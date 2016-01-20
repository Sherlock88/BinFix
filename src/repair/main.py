import os
from os.path import join, exists, abspath, basename
import shutil
import argparse
import time
import json
import logging
import time
import sys

from project import Validation, Frontend, Backend, CompilationError
from utils import format_time, time_limit, TimeoutException
from runtime import Dump, Trace
from transformation import RepairableTransformer, SuspiciousTransformer, \
                           FixInjector, TransformationError
from testing import Tester
from inference import Inferrer, InferenceError
from synthesis import Synthesizer


logger = logging.getLogger("repair")


SYNTHESIS_LEVELS = ['alternatives',
                    'integer-constants',
                    'boolean-constants',
                    'variables',
                    'basic-arithmetic',
                    'basic-logic',
                    'basic-inequalities',
                    'extended-arithmetic',
                    'extended-logic',
                    'extended-inequalities',
                    'mixed-conditional',
                    'conditional-arithmetic']


DEFECT_CLASSES = ['if-conditions',
                  'assignments',
                  'loop-conditions',
                  'guards']


DEFAULT_DEFECTS = ['if-conditions', 'assignments']


KLEE_SEARCH_STRATEGIES = ['dfs', 'bfs', 'random-state', 'random-path',
                          'nurs:covnew', 'nurs:md2u', 'nurs:depth',
                          'nurs:icnt', 'nurs:cpicnt', 'nurs:qc']


DEFAULT_GROUP_SIZE = 2


DEFAULT_INITIAL_TESTS = 2


sys.setrecursionlimit(10000)  # Otherwise inference.get_vars fails


class Binfix:

    def __init__(self, working_dir, config):
        self.working_dir = working_dir
        self.config = config
        extracted = join(working_dir, 'extracted')
        os.mkdir(extracted)

        angelic_forest_file = join(working_dir, 'last-angelic-forest.json')

        self.infer_spec = Inferrer(config, tester)


    def generate_patch(self):
        while len(negative) > 0 and len(suspicious) > 0:
            if self.config['use_semfix_syn']:
                # prepare a clean directory
                shutil.rmtree(join(self.working_dir, 'semfix-syn-input'),
                              ignore_errors='true')

            angelic_forest = dict()
            inference_failed = False
            for test in repair_suite:
                try:
                    angelic_forest[test] = self.infer_spec(self.backend_src, test, self.dump[test])
                    print " | ".join(array)
                    if len(angelic_forest[test]) == 0:
                        inference_failed = True
                        break
                except InferenceError:
                    inference_failed = True
                   break
            
if __name__ == "__main__":

    parser = argparse.ArgumentParser('angelix')
    parser.add_argument('src', metavar='SOURCE', help='source directory')
    parser.add_argument('buggy', metavar='BUGGY', help='relative path to buggy file')
    parser.add_argument('oracle', metavar='ORACLE', help='oracle script')
    parser.add_argument('tests', metavar='TEST', nargs='+', help='test case')
    parser.add_argument('--golden', metavar='DIR', help='golden source directory')
    parser.add_argument('--assert', metavar='FILE', help='assert expected outputs')
    parser.add_argument('--defect', metavar='CLASS', nargs='+',
                        default=DEFAULT_DEFECTS,
                        choices=DEFECT_CLASSES,
                        help='defect classes (default: %(default)s). choices: ' + ', '.join(DEFECT_CLASSES))
    parser.add_argument('--lines', metavar='LINE', type=int, nargs='+', help='suspicious lines (default: all)')
    parser.add_argument('--configure', metavar='CMD', default=None,
                        help='configure command in the form of shell command (default: %(default)s)')
    parser.add_argument('--build', metavar='CMD', default='make -e',
                        help='build command in the form of simple shell command (default: %(default)s)')
    parser.add_argument('--timeout', metavar='MS', type=int, default=None,
                        help='total repair timeout (default: %(default)s)')
    parser.add_argument('--initial-tests', metavar='NUM', type=int, default=DEFAULT_INITIAL_TESTS,
                        help='initial repair test suite size (default: %(default)s)')
    parser.add_argument('--test-timeout', metavar='MS', type=int, default=None,
                        help='test case timeout (default: %(default)s)')
    parser.add_argument('--group-size', metavar='NUM', type=int, default=DEFAULT_GROUP_SIZE,
                        help='number of statements considered at once (default: %(default)s)')
    parser.add_argument('--group-by-score', action='store_true',
                        help='group statements by suspiciousness score (default: grouping by location)')
    parser.add_argument('--suspicious', metavar='NUM', type=int, default=20,
                        help='total number of suspicious statements (default: %(default)s)')
    parser.add_argument('--localization', default='jaccard', choices=['jaccard', 'ochiai', 'tarantula'],
                        help='formula for localization algorithm (default: %(default)s)')
    parser.add_argument('--ignore-trivial', action='store_true',
                        help='ignore trivial expressions: variables and constants (default: %(default)s)')
    parser.add_argument('--max-angelic-paths', metavar='NUM', type=int, default=None,
                        help='max number of angelic paths for a test case (default: %(default)s)')
    parser.add_argument('--klee-search', metavar='HEURISTIC', default=None,
                        choices=KLEE_SEARCH_STRATEGIES,
                        help='KLEE search heuristic (default: KLEE\'s default). choices: ' + ', '.join(KLEE_SEARCH_STRATEGIES))
    parser.add_argument('--klee-max-forks', metavar='NUM', type=int, default=None,
                        help='KLEE max number of forks (default: %(default)s)')
    parser.add_argument('--klee-max-depth', metavar='NUM', type=int, default=None,
                        help='KLEE max symbolic branches (default: %(default)s)')
    parser.add_argument('--klee-timeout', metavar='SEC', type=int, default=None,
                        help='KLEE timeout (default: %(default)s)')
    parser.add_argument('--klee-solver-timeout', metavar='SEC', type=int, default=None,
                        help='KLEE solver timeout (default: %(default)s)')
    parser.add_argument('--klee-debug', action='store_true',
                        help='print instructions executed by KLEE (default: %(default)s)')
    parser.add_argument('--klee-ignore-errors', action='store_true',
                        help='Don\'t terminate on memory errors (default: %(default)s)')
    parser.add_argument('--synthesis-timeout', metavar='MS', type=int, default=30000, # 30 sec
                        help='synthesis timeout (default: %(default)s)')
    parser.add_argument('--synthesis-levels', metavar='LEVEL', nargs='+',
                        choices=SYNTHESIS_LEVELS,
                        default=['alternatives', 'integer-constants', 'boolean-constants'],
                        help='component levels (default: %(default)s). choices: ' + ', '.join(SYNTHESIS_LEVELS))
    parser.add_argument('--synthesis-global-vars', action='store_true',
                        help='use global program variables for synthesis (default: %(default)s)')
    parser.add_argument('--synthesis-func-params', action='store_true',
                        help='use function parameters as variables for synthesis (default: %(default)s)')
    parser.add_argument('--synthesis-used-vars', action='store_true',
                        help='use variables that are used in scope for synthesis (default: %(default)s)')
    parser.add_argument('--synthesis-ptr-vars', action='store_true',
                        help='use pointer variables for synthesis (default: %(default)s)')
    parser.add_argument('--semfix', action='store_true',
                        help='enable SemFix mode (default: %(default)s)')
    parser.add_argument('--use-semfix-synthesizer', action='store_true',
                        help='use SemFix synthesizer (default: %(default)s)')
    parser.add_argument('--max-z3-trials', metavar='NUM', type=int, default=2,
                        help='maxium Z3 trials when using SemFix synthesizer (default: %(default)s)')
    parser.add_argument('--binfix', action='store_true', default=False,
                        help='enable BinFix mode (default: %(default)s)')
    parser.add_argument('--dump-only', action='store_true',
                        help='dump actual outputs for given tests (default: %(default)s)')
    parser.add_argument('--synthesis-only', metavar="FILE", default=None,
                        help='synthesize and validate patch from angelic forest (default: %(default)s)')
    parser.add_argument('--verbose', action='store_true',
                        help='print compilation and KLEE messages (default: %(default)s)')
    parser.add_argument('--quiet', action='store_true',
                        help='print only errors (default: %(default)s)')

    args = parser.parse_args()

    FORMAT = '%(levelname)-8s %(name)-15s %(message)s'
    if args.quiet:
        logging.basicConfig(level=logging.WARNING, format=FORMAT)
    else:
        logging.basicConfig(level=logging.INFO, format=FORMAT)

    working_dir = join(os.getcwd(), ".angelix")
    if exists(working_dir):
        shutil.rmtree(working_dir)
    os.mkdir(working_dir)

    if vars(args)['assert'] is not None and not args.dump_only:
        with open(vars(args)['assert']) as output_file:
            asserts = json.load(output_file)
    else:
        asserts = None

    if 'guards' in args.defect and 'assignments' in args.defect:
        logger.error('\'guards\' and \'assignments\' defect classes are currently incompatible')
        exit(1)

    if args.semfix:
        if not (args.defect == DEFAULT_DEFECTS):
            logger.warning('--semfix disables --defect option')
        if args.ignore_trivial:
            logger.warning('--semfix disables --ignore-trivial option')
        if not (args.group_size == DEFAULT_GROUP_SIZE):
            logger.warning('--semfix disables --group-size option')
        args.group_size = 1

    if args.dump_only:
        if args.golden is not None:
            logger.warning('--dump-only disables --golden option')
        if asserts is not None:
            logger.warning('--dump-only disables --assert option')

    config = dict()
    config['initial_tests']         = args.initial_tests
    config['binfix']                = args.binfix
    config['semfix']                = args.semfix
    config['use_semfix_syn']        = args.use_semfix_synthesizer    
    config['max_z3_trials']         = args.max_z3_trials
    config['defect']                = args.defect
    config['test_timeout']          = args.test_timeout
    config['group_size']            = args.group_size
    config['group_by_score']        = args.group_by_score
    config['suspicious']            = args.suspicious
    config['localization']          = args.localization
    config['ignore_trivial']        = args.ignore_trivial
    config['max_angelic_paths']     = args.max_angelic_paths
    config['klee_max_forks']        = args.klee_max_forks
    config['klee_max_depth']        = args.klee_max_depth
    config['klee_search']           = args.klee_search
    config['klee_timeout']          = args.klee_timeout
    config['klee_solver_timeout']   = args.klee_solver_timeout
    config['klee_debug']            = args.klee_debug
    config['klee_ignore_errors']    = args.klee_ignore_errors
    config['synthesis_timeout']     = args.synthesis_timeout
    config['synthesis_levels']      = args.synthesis_levels
    config['synthesis_global_vars'] = args.synthesis_global_vars
    config['synthesis_func_params'] = args.synthesis_func_params
    config['synthesis_used_vars']   = args.synthesis_used_vars
    config['synthesis_ptr_vars']    = args.synthesis_ptr_vars
    config['synthesis_only']        = args.synthesis_only
    config['verbose']               = args.verbose

    if args.verbose:
        for key, value in config.items():
            logger.info('option {} = {}'.format(key, value))

    tool = Angelix(working_dir,
                   tests=args.tests,
                   config=config)

    if args.dump_only:
        try:
            dump = tool.dump_outputs()
            with open('dump.json', 'w') as output_file:
                asserts = json.dump(dump, output_file, indent=2)
            logger.info('outputs successfully dumped (see dump.json)')
            exit(0)
        except (CompilationError, TransformationError):
            logger.info('failed to dump outputs')
            exit(1)

    start = time.time()

    def repair():
        if args.synthesis_only is not None:
            return tool.synthesize_from(args.synthesis_only)
        else:
            return tool.generate_patch()

    try:
        if args.timeout is not None:
            with time_limit(args.timeout):
                patch = repair()
        else:
            patch = repair()
    except TimeoutException:
        logger.info("failed to generate patch (timeout)")
        print('TIMEOUT')
        exit(0)
    except (CompilationError, InferenceError, TransformationError):
        logger.info("failed to generate patch")
        print('FAIL')
        exit(1)

    end = time.time()
    elapsed = format_time(end - start)

    if patch is None:
        logger.info("no patch generated in {}".format(elapsed))
        print('FAIL')
        exit(0)
    else:
        if not config['synthesis_only']:
            patch_file = basename(abspath(args.src)) + '-' + time.strftime("%Y-%b%d-%H%M%S") + '.patch'
            logger.info("patch successfully generated in {} (see {})".format(elapsed, patch_file))
            print('SUCCESS')
            with open(patch_file, 'w+') as file:
                for line in patch:
                    file.write(line)
        else:
            logger.info("patch successfully generated in {}".format(elapsed))
            print('SUCCESS')
        exit(0)
