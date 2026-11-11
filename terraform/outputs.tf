output "kubeconfig_path" {
  value = kind_cluster.this.kubeconfig_path
}

output "endpoint" {
  value = kind_cluster.this.endpoint
}
