#!/usr/bin/env bash

set -e

echo -n ""

# For each EC2 resource, list and delete until none remain.

# 1) Instances (terminate all non-terminated)
while true; do
  ids=$(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text 2>/dev/null)
  if [[ -z "${ids}" ]]; then
    break
  fi
  # Print one line per instance
  for id in ${ids}; do echo -e "ec2	instance	${id}"; done
  aws ec2 terminate-instances --instance-ids ${ids}
done

# 2) Load balancer listeners (ALB/NLB)
while true; do
  lbs=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null)
  [[ -z "${lbs}" ]] && break
  any=0
  for lb in ${lbs}; do
    listeners=$(aws elbv2 describe-listeners --load-balancer-arn "${lb}" --query 'Listeners[].ListenerArn' --output text 2>/dev/null)
    if [[ -n "${listeners}" ]]; then
      for lst in ${listeners}; do
        echo -e "ec2	lb-listener	${lst}"
        aws elbv2 delete-listener --listener-arn "${lst}"
        any=1
      done
    fi
  done
  [[ ${any} -eq 0 ]] && break
done

# 3) Target groups
while true; do
  tgs=$(aws elbv2 describe-target-groups --query 'TargetGroups[].TargetGroupArn' --output text 2>/dev/null)
  if [[ -z "${tgs}" ]]; then
    break
  fi
  for tg in ${tgs}; do
    echo -e "ec2	target-group	${tg}"
    aws elbv2 delete-target-group --target-group-arn "${tg}"
  done
done

# 4) Load balancers
while true; do
  lbs=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?State.Code!=`deleting`].LoadBalancerArn' --output text 2>/dev/null)
  if [[ -z "${lbs}" ]]; then
    break
  fi
  for lb in ${lbs}; do
    echo -e "ec2	load-balancer	${lb}"
    aws elbv2 delete-load-balancer --load-balancer-arn "${lb}"
  done
done

# 5) Spot instance requests (cancel)
while true; do
  srs=$(aws ec2 describe-spot-instance-requests --query 'SpotInstanceRequests[].SpotInstanceRequestId' --output text 2>/dev/null)
  if [[ -z "${srs}" ]]; then
    break
  fi
  for sr in ${srs}; do echo -e "ec2	spot-request	${sr}"; done
  aws ec2 cancel-spot-instance-requests --spot-instance-request-ids ${srs}
done

# 6) Network interfaces (delete)
while true; do
  enis=$(aws ec2 describe-network-interfaces --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null)
  if [[ -z "${enis}" ]]; then
    break
  fi
  for eni in ${enis}; do
    echo -e "ec2	eni	${eni}"
    aws ec2 delete-network-interface --network-interface-id "${eni}"
  done
done

# 7) Volumes (delete available)
while true; do
  vols=$(aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[].VolumeId' --output text 2>/dev/null)
  if [[ -z "${vols}" ]]; then
    break
  fi
  for v in ${vols}; do
    echo -e "ec2	volume	${v}"
    aws ec2 delete-volume --volume-id "${v}"
  done
done

# 8) AMIs (deregister images you own)
while true; do
  imgs=$(aws ec2 describe-images --owners self --query 'Images[].ImageId' --output text 2>/dev/null)
  if [[ -z "${imgs}" ]]; then
    break
  fi
  for i in ${imgs}; do
    echo -e "ec2	ami	${i}"
    aws ec2 deregister-image --image-id "${i}"
  done
done

# 9) Snapshots (delete snapshots you own)
while true; do
  snaps=$(aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[].SnapshotId' --output text 2>/dev/null)
  if [[ -z "${snaps}" ]]; then
    break
  fi
  for s in ${snaps}; do
    echo -e "ec2	snapshot	${s}"
    aws ec2 delete-snapshot --snapshot-id "${s}"
  done
done

# 10) Elastic IPs (release)
while true; do
  eips=$(aws ec2 describe-addresses --query 'Addresses[].AllocationId' --output text 2>/dev/null)
  if [[ -z "${eips}" ]]; then
    break
  fi
  for a in ${eips}; do
    echo -e "ec2	elastic-ip	${a}"
    aws ec2 release-address --allocation-id "${a}"
  done
done

# 11) Security groups (delete non-default)
while true; do
  sgs=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null)
  if [[ -z "${sgs}" ]]; then
    break
  fi
  for sg in ${sgs}; do
    echo -e "ec2	security-group	${sg}"
    aws ec2 delete-security-group --group-id "${sg}"
  done
done

# 12) Placement groups (delete)
while true; do
  pgs=$(aws ec2 describe-placement-groups --query 'PlacementGroups[].GroupName' --output text 2>/dev/null)
  if [[ -z "${pgs}" ]]; then
    break
  fi
  for pg in ${pgs}; do
    echo -e "ec2	placement-group	${pg}"
    aws ec2 delete-placement-group --group-name "${pg}"
  done
done

# 13) Launch templates (delete)
while true; do
  lts=$(aws ec2 describe-launch-templates --query 'LaunchTemplates[].LaunchTemplateId' --output text 2>/dev/null)
  if [[ -z "${lts}" ]]; then
    break
  fi
  for lt in ${lts}; do
    echo -e "ec2	launch-template	${lt}"
    aws ec2 delete-launch-template --launch-template-id "${lt}"
  done
done
echo -n ""
