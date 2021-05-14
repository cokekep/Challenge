import argparse, boto3, pprint, sys, time
from botocore.config import Config

my_config = Config(
    region_name = 'eu-central-1',
    signature_version = 'v4',
    retries = {
        'max_attempts': 10,
        'mode': 'standard'
    }
)

# Create the parser
my_parser = argparse.ArgumentParser(description='Set Default Capacities')

# Add the arguments
my_parser.add_argument('--default', action='store', type=bool, default=False)

# Execute the parse_args() method
args = my_parser.parse_args()

switch_to_default = args.default

DEFAULT_MINIMUM_SIZE = 2
DEFAULT_DESIRED_CAPACITY = 3
DEFAULT_MAXIMUM_SIZE = 5

def capacity_value(message):
  while True:
    try:
       capacity = int(input(message))       
    except ValueError:
       print("Not an integer! Try again.")
       continue
    else:
       return capacity


autoscaling_client = boto3.client('autoscaling',config=my_config)

paginator = autoscaling_client.get_paginator('describe_auto_scaling_groups')
page_iterator = paginator.paginate(
    PaginationConfig={'PageSize': 100}
)

filtered_asgs = page_iterator.search(
    'AutoScalingGroups[] | [?contains(Tags[?Key==`{}`].Value, `{}`)]'.format(
        'Name', 'im-asg')
)

try:
    asg = next(filtered_asgs)
except StopIteration:
    print("There's no ASG with that Tag")
    sys.exit()

if not switch_to_default:
    MINIMUM_SIZE = capacity_value(f'Please input your ASG Minimum Size Change (Current_ASG_MinSize = {asg["MinSize"]}): ')
    DESIRED_CAPACITY = capacity_value(f'Please input your ASG Desired Capacity Change (Current_ASG_DesiredCapacity = {asg["DesiredCapacity"]}): ')
    MAXIMUM_SIZE = capacity_value(f'Please input your ASG Maximum Size Change (Current_ASG_MaxSize = {asg["MaxSize"]}): ')


OPERATION = ""

MinSize = DEFAULT_MINIMUM_SIZE if switch_to_default else MINIMUM_SIZE
MaxSize = DEFAULT_MAXIMUM_SIZE if switch_to_default else MAXIMUM_SIZE
DesiredCapacity = DEFAULT_DESIRED_CAPACITY if switch_to_default else DESIRED_CAPACITY

if DesiredCapacity > asg["DesiredCapacity"]:
    OPERATION = "ScaleOut"
elif DesiredCapacity < asg["DesiredCapacity"]:
    OPERATION = "ScaleIn"
else:
    OPERATION = "None"

try:
    update_auto_scale_response = autoscaling_client.update_auto_scaling_group(
        AutoScalingGroupName=asg["AutoScalingGroupName"],
        MinSize=MinSize,
        MaxSize=MaxSize,
        DesiredCapacity=DesiredCapacity,
    )
    if (update_auto_scale_response["ResponseMetadata"]["HTTPStatusCode"] != 200):
        raise Exception("Error in updating Autoscaling Group")
    print("Updating Autoscaling group")
except:
    print("Error in updating Autoscaling Group")
    sys.exit()


while True:
    try:
        updated_asg_response = autoscaling_client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[
            asg["AutoScalingGroupName"],
            ]
        )
        updated_asg = updated_asg_response["AutoScalingGroups"][0]
        updated_asg_instances = updated_asg["Instances"]
        inservice_instances = [instance for instance in updated_asg_instances if instance["LifecycleState"] == "InService"]
        if updated_asg["DesiredCapacity"] == DEFAULT_DESIRED_CAPACITY and updated_asg["MaxSize"] == DEFAULT_MAXIMUM_SIZE and updated_asg["MinSize"] == DEFAULT_MINIMUM_SIZE:
            if len(inservice_instances) == DesiredCapacity:
                print("InService Instances is Equal to Desired Capacity")
                print("Capacity Switched to default")
                break
        elif len(inservice_instances) == DesiredCapacity:
            print("InService Instances is Equal to Desired Capacity")
            break
        print("Waiting ...")
        time.sleep(5)
    except:
        print("Error checking InService Instances")


