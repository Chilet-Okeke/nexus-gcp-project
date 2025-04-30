# Building the project infrastructure on google cloud CLI

Open the cloud shell from your google cloud console account at https://console.cloud.com
Open the cloud shell directly from https://shell.cloud.google.com

## 1. Set Project

### List available projects

```bash
gcloud projects list
```

- Copy the project id of the project you want to use and replace <nexus-project-id01> in the shell

```bash
gcloud config set project --project nexus-project-id01
```

Now you can perform actions within the project without worrying about project tags

## 2. Setup Network

```bash
gcloud compute networks create mynetwork --subnet-mode AUTO
```

You can verify the network details with

```bash
gcloud compute networks list
gcloud compute networks describe mynetwork
```

You can verify the subnets created with

```bash
gcloud compute networks subnets list
```

## 3. Setup your vm instance

```bash
gcloud compute instances create nexusvm \
    --zone=us-central1-b \
    --machine-type=e2-standard-4 \
    --network=mynetwork \
    --subnet=mynetwork \
    --boot-disk-size=200GB \
    --boot-disk-type=pd-ssd \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --tags=nexus-server
```

## 4. Setup Firewall rules

### Create firewall-rule to allow nexus on port 8081

```bash
gcloud compute firewall-rules create allow-nexus-8081 \
    --network=mynetwork \
    --allow=tcp:8081 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=nexus-server \
    --description="Allow Nexus GUI access"
```

### Create firewall-rule to allow ssh and iap

```bash
gcloud compute firewall-rules create allow-ssh-iap \
    --network=mynetwork \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow SSH via IAP"
```

- On Port 8081: Where Nexus GUI will be offered (HTTP). This is a test project so all IPs ranges are allowed.
  For production/best practice, please restrict --source-ranges to your team’s IP range or use a load balancer.
  On Port 22: You can SSH into chilets-nexusvm via IAP as there is no external ip.

### Setup Cloud NAT (optional)

- Create NAT router

```bash
gcloud compute routers create nat-router \
    --network=mynetwork \
    --region=us-central1
```

```bash
gcloud compute routers nats create nat-config \
    --router=nat-router \
    --region=us-central1 \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges
```

### Create ingress/egress rules

```bash
gcloud compute firewall-rules create allow-internal-icmp \
    --network=mynetwork \
    --direction=INGRESS \
    --action=ALLOW \
    --rules=icmp \
    --source-ranges=10.128.0.0/9 \
    --priority=1000
```

- Create egress rules

```bash
gcloud compute firewall-rules create allow-egress-all \
    --network=mynetwork \
    --direction=EGRESS \
    --action=ALLOW
    --rules=all \
    --priority=1000
```

## 5. SSH into the vm

```bash
gcloud compute ssh nexusvm --zone=us-central1-b
#You can use the --tunnel-through-iap tag if the vm is setup no external ip
```
