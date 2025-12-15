output "kube_config_raw" {
  description = "Raw kubeconfig to access the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
