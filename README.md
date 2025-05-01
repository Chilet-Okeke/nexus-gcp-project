# Setting up Nexus Registry on GCP with Java and Docker

This project deploys a Sonatype Nexus Repository Manager on a Google Cloud Platform (GCP) VM (nexusvm) using Java, Docker and Docker Compose, integrated with Terraform for infrastructure, Prometheus for monitoring, and Jenkins for CI/CD. It serves as an artifact registry for Docker images and Maven packages, supporting GKE deployments and CRM/ERP workflows.

## Prerequisites

- GCP Account: Project `nexus-project-id01` with the network `mynetwork` and Cloud NAT.
- Tools: `gcloud` CLI, Terraform, Docker, Docker Compose, Git.
- Access: SSH access to `nexusvm` via IAP.

## Repository Structure

```bash
nexus-gcp-project/
├── terraform/
│ └── nexus-vm.tf # GCP VM and firewall setup
├── gcloud cli/
│ └── gcloud-cli.md # Gcloud CLi for VM and firewall rules setup
├── docker/
│ └── docker-compose.yml # Nexus Docker Compose config
├── monitoring/
│ └── prometheus.yml # Prometheus monitoring config
├── ci/
│ └── Jenkinsfile # Jenkins CI/CD pipeline
├── README.md # Project documentation
└── LICENCE # MIT Licence
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/chilet-okeke/nexus-gcp-project.git
cd nexus-gcp-project
```

### 2. Deploy GCP Infrastructure

- Go through the nexus-vm.tf file and set your preferred details (name, project, tags etc)

```bash
cd terraform
terraform init
terraform apply -var="gcp-project-id"
```

- Create `nexus-vm` VM and firewall rules (`allow-nexus-8081`, `allow-egress-all`).

### 3. Observe the VM details then SSH into VM

```bash
gcloud compute instances list | grep nexus-vm
```

- Copy out the external ip and save to your notepad

```bash
gcloud compute ssh nexus-vm --zone=us-central1-f --project=gcp-project-id --tunnel-through-iap
```

### 4. Install Docker

```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
```

### 5. Run Nexus with Docker (Setup 1)

```bash
sudo mkdir -p /opt/nexus-data
sudo chown -R 200:200 /opt/nexus-data
sudo docker run -d --name nexus -p 8081:8081 -v /opt/nexus-data:/nexus-data sonatype/nexus3
```

- Give it a few minutes then run this command to Verify:
  ```bash
  sudo docker ps -a
  netstat -tuln | grep 8081
  ```
- If docker stopped running or exited:

```bash
  sudo docker start nexus
  sudo docker ps -a
```

### 6. Run Nexus with Docker Compose (Setup 2 - Recommended)

```bash
sudo apt-get install -y docker-compose-plugin
docker compose version
cd docker
sudo docker compose up -d
```

- You can also try setting docker compose up manually, if it's not recognised

```bash
 mkdir -p ~/.docker/cli-plugins
 curl -SL https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
 chmod +x ~/.docker/cli-plugins/docker-compose
```

- Verify if nexus is working:

```bash
  sudo docker logs -f nexus
```

### 7. Access Nexus GUI

- URL: `http://<nexus-vm-external-ip>:8081`
- Username: `admin`
- Password:
- Use this command to gain the password

```bash
  sudo docker exec nexus cat /nexus-data/admin.password
```

### 8. Monitor with Prometheus

- Update `monitoring/prometheus.yml` with `<nexus-vm-external-ip>`.
- Deploy Prometheus (e.g., via Helm on GKE).

### 9. Automate with Jenkins

- Use `ci/Jenkinsfile` in your Jenkins pipeline to deploy Nexus.

## Integration

- GKE: Host Docker images in Nexus:

```bash
  docker tag nginx:latest <nexus-vm-ip>:8082/nginx:latest
  docker push <nexus-vm-ip>:8082/nginx:latest
```

- **Prometheus/OpenTelemetry**: Monitor Nexus metrics.
- **Jenkins**: Automate deployments via CI/CD.

## Cleanup

```bash
sudo docker stop nexus
sudo docker rm nexus
sudo rm -rf /opt/nexus-data
```

- check for the host path and delete if it still exists
  It will look like this: /nexus/host-path

```bash
 sudo docker inspect nexus --format='{{ range .Mounts }}{{ .Source }} -> {{ .Destination }}{{ "\n" }}{{ end }}'
```

```bash
 sudo rm -rf /nexus/host-path
```

```bash
 terraform destroy
```

## Push to Github

In your terminal enter this command

```bash
git add .
git commit -m "Initial setup: Nexus with Google Cloud CLI, Docker, Terraform, Prometheus, Jenkins, and README"
git push origin main
```

## Licence

MIT Licence (see `LICENCE`).

## Contact

Connect with me on [LinkedIn](https://linkedin.com/in/chilet) for feedback or collaboration!
