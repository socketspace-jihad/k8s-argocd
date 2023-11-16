variable "name" {
    description = "Name of the cluster"
}

variable "total_worker_node" {
    type = number
    description = "Number of worker node that you want to add into cluster"
    default = 3
}

variable "http_host_port"{
    description = "HOST/local HTTP PORT that will expose to access the cluster service/ingress "
}

variable "https_host_port"{
    description = "HOST/local HTTPs PORT that will expose to access the cluster service/ingress "
}