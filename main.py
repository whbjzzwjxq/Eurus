import argparse
from impl.deploy.all import bmk_selector
from impl.utils import init_config
from impl.init_slither import gen_slither_contracts
from impl.static_analysis import analysis_read_and_write

parser = argparse.ArgumentParser()
parser.add_argument("-d", "--directory", help="Target contracts directory")
parser.add_argument("-tu", "--testusedef", help="Run use-def analysis", action="store_true")
parser.add_argument("-tmu", "--testmockusedef", help="Generate use-def graph", action="store_true")
parser.add_argument("-tb", "--testbaseline", help="Run baseline", action="store_true")
parser.add_argument("-gt", "--groundtruth", help="Run ground truth", action="store_true")
parser.add_argument("-gu", "--graphusedef", help="Generate use-def graph", action="store_true")

def _main():
    args = parser.parse_args()
    config = init_config(args.directory)
    deployer = bmk_selector[config.project_name]()
    if args.testusedef:
        deployer.syn_usedef()
    elif args.testbaseline:
        deployer.syn_baseline()
    elif args.testmockusedef:
        deployer.run_mock_usedef()
    elif args.groundtruth:
        deployer.run_ground_truth()
    elif args.graphusedef:
        ctrt_slis, config = gen_slither_contracts(args.directory)
        static_graph = analysis_read_and_write(ctrt_slis, config)
        static_graph.draw_graphviz(name=config.project_name)
    else:
        print("Do nothing")


if __name__ == "__main__":
    _main()
