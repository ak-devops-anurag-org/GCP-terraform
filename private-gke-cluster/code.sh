gcloud beta container \
    --project \
"ak-here" clusters create "private-gke-cluster" \
    --zone \
"asia-south2-b" \
    --no-enable-basic-auth \
    --cluster-version \
"1.33.5-gke.1080000" \
    --release-channel \
"regular" \
    --machine-type \
"e2-micro" \
    --image-type \
"COS_CONTAINERD" \
    --disk-type \
"pd-balanced" \
    --disk-size \
"15" \
    --metadata \
disable-legacy-endpoints=true \
    --service-account \
"sa-bastion-vm@ak-here.iam.gserviceaccount.com" \
    --num-nodes \
"1" \
    --logging=NONE \
    --enable-private-nodes \
    --enable-ip-alias \
    --network \
"projects/ak-here/global/networks/ak-vpc" \
    --subnetwork \
"projects/ak-here/regions/asia-south2/subnetworks/ak-vpc-subnet" \
    --cluster-secondary-range-name \
"ak-gke-services-range" \
    --services-secondary-range-name \
"ak-gke-pods-range" \
    --no-enable-intra-node-visibility \
    --default-max-pods-per-node \
"110" \
    --enable-ip-access \
    --security-posture=standard \
    --workload-vulnerability-scanning=disabled \
    --no-enable-google-cloud-access \
    --addons \
HorizontalPodAutoscaling,HttpLoadBalancing \
    --enable-autoupgrade \
    --enable-autorepair \
    --max-surge-upgrade \
1 \
    --max-unavailable-upgrade \
0 \
    --binauthz-evaluation-mode=DISABLED \
    --no-enable-managed-prometheus \
    --enable-shielded-nodes \
    --shielded-integrity-monitoring \
    --no-shielded-secure-boot \
    --node-locations \
"asia-south2-b"




# -- v2.0 --
gcloud beta container \
    --project \
"ak-here" clusters create "ak-gkeprivate \
    --cluster" \
    --zone \
"asia-south2-b" \
    --no-enable-basic-auth \
    --cluster-version \
"1.33.5-gke.1080000" \
    --release-channel \
"regular" \
    --machine-type \
"e2-micro" \
    --image-type \
"COS_CONTAINERD" \
    --disk-type \
"pd-balanced" \
    --disk-size \
"10" \
    --metadata \
disable-legacy-endpoints=true \
    --service-account \
"sa-bastion-vm@ak-here.iam.gserviceaccount.com" \
    --num-nodes \
"1" \
    --logging=NONE \
    --enable-private-nodes \
    --enable-ip-alias \
    --network \
"projects/ak-here/global/networks/ak-vpc" \
    --subnetwork \
"projects/ak-here/regions/asia-south2/subnetworks/ak-vpc-subnet" \
    --cluster-secondary-range-name \
"ak-gke-services-range" \
    --services-secondary-range-name \
"ak-gke-pods-range" \
    --no-enable-intra-node-visibility \
    --default-max-pods-per-node \
"110" \
    --enable-ip-access \
    --security-posture=standard \
    --workload-vulnerability-scanning=disabled \
    --no-enable-google-cloud-access \
    --addons \
HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
    --enable-autoupgrade \
    --enable-autorepair \
    --max-surge-upgrade \
1 \
    --max-unavailable-upgrade \
0 \
    --binauthz-evaluation-mode=DISABLED \
    --no-enable-managed-prometheus \
    --enable-shielded-nodes \
    --shielded-integrity-monitoring \
    --no-shielded-secure-boot \
    --node-locations \
"asia-south2-b"




# --v 1.0 --
gcloud beta container \
    --project \
"ak-here" clusters create "private-gke-cluster" \
    --zone \
"asia-south2-a" \
    --no-enable-basic-auth \
    --cluster-version \
"1.33.5-gke.1080000" \
    --release-channel \
"regular" \
    --machine-type \
"e2-micro" \
    --image-type \
"COS_CONTAINERD" \
    --disk-type \
"pd-balanced" \
    --disk-size \
"10" \
    --metadata \
disable-legacy-endpoints=true \
    --service-account \
"sa-bastion-vm@ak-here.iam.gserviceaccount.com" \
    --num-nodes \
"1" \
    --logging=NONE \
    --enable-private-nodes \
    --enable-ip-alias \
    --network \
"projects/ak-here/global/networks/ak-vpc" \
    --subnetwork \
"projects/ak-here/regions/asia-south2/subnetworks/ak-vpc-subnet" \
    --no-enable-intra-node-visibility \
    --default-max-pods-per-node \
"110" \
    --enable-ip-access \
    --security-posture=standard \
    --workload-vulnerability-scanning=disabled \
    --enable-master-authorized-networks \
    --master-authorized-networks \
10.10.0.0/20 \
    --no-enable-google-cloud-access \
    --addons \
HorizontalPodAutoscaling \
    --enable-autoupgrade \
    --enable-autorepair \
    --max-surge-upgrade \
1 \
    --max-unavailable-upgrade \
0 \
    --binauthz-evaluation-mode=DISABLED \
    --no-enable-managed-prometheus \
    --no-shielded-integrity-monitoring \
    --no-shielded-secure-boot \
    --node-locations \
"asia-south2-a"


# 