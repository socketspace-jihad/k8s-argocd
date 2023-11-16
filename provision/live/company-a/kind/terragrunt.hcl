terraform {
    source = "../../../modules//kind/clusters"
}

// Add generics
inputs = {
    name="company-cluster-1"
    http_host_port=8086
    https_host_port=8448
}