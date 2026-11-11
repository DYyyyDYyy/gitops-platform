variable "cluster_name" {
  type    = string
  default = "gitops"
}

variable "node_image" {
  type    = string
  default = "kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5"
}

variable "workers" {
  type    = number
  default = 2
}

variable "repo_url" {
  description = "Git repository Argo CD syncs from."
  type        = string
  default     = "https://github.com/DYyyyDYyy/gitops-platform.git"
}

variable "git_revision" {
  description = "Branch, tag or commit for all Argo CD apps (CI passes the commit SHA)."
  type        = string
  default     = "main"
}

variable "argocd_chart_version" {
  type    = string
  default = "10.18.0"
}
