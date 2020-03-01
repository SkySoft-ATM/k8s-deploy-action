# k8s-deploy-action 

This action deploys a docker image on a GKE cluster on the given namespaces

# Usage
<!-- start usage -->
```yaml
- uses: SkySoft-ATM/k8s-deploy-action@v9
  with:
    # GCloud token
    gcloud_token:  ${{ secrets.MY_GCLOUD_TOKEN_SECRET }}
    
    # Namespaces separated by a space
    namespaces: dev uat pprod

    # Docker image name
    # Default:  ${{ github.event.repository.name }}
    image_name: myDockerImage

    # Cluster name
    # Default:  sk-cluster-1
    cluster_name: myClusterName
    
    # GKE Zone
    # Default:  europe-west1-b
    zone: somewhere-in-the-cloud
    
    # GKE Project
    # Default:  ccs-skyserver
    project: myProject
```
<!-- end usage -->