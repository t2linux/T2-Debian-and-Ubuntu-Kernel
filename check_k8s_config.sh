#!/bin/bash
#
# Verify that a kernel .config carries the options Kubernetes nodes rely on
# (container runtime, cgroup v2, kube-proxy, common CNIs and eBPF tooling).
# Fails loudly so a template refresh can't silently drop one of them again.
#
# Usage: ./check_k8s_config.sh <path/to/.config>

set -eu -o pipefail

CONFIG_FILE="${1:-.config}"

[ -f "${CONFIG_FILE}" ] || {
  echo "Kernel config not found: ${CONFIG_FILE}" >&2
  exit 1
}

# Options that must be built in or available as a module.
REQUIRED=(
  # Namespaces and container runtime
  NAMESPACES UTS_NS IPC_NS PID_NS NET_NS USER_NS
  POSIX_MQUEUE KEYS SECCOMP SECCOMP_FILTER OVERLAY_FS
  # cgroup v2 resource control used by kubelet
  CGROUPS MEMCG CPUSETS CGROUP_PIDS CGROUP_BPF CGROUP_SCHED
  FAIR_GROUP_SCHED CFS_BANDWIDTH BLK_CGROUP CGROUP_HUGETLB PSI
  # Pod networking and kube-proxy (iptables, ipvs and nftables modes)
  VETH BRIDGE BRIDGE_NETFILTER VXLAN
  NF_CONNTRACK NF_NAT IP_NF_IPTABLES IP_NF_FILTER IP_NF_NAT IP6_NF_IPTABLES
  NETFILTER_XT_MATCH_CONNTRACK NETFILTER_XT_MATCH_ADDRTYPE NETFILTER_XT_MATCH_COMMENT
  NETFILTER_XT_MATCH_MULTIPORT NETFILTER_XT_MATCH_IPVS NETFILTER_XT_MARK
  IP_SET IP_VS IP_VS_RR IP_VS_WRR IP_VS_SH NF_TABLES NFT_COMPAT
  # eBPF dataplanes and runtime security (Cilium, Tetragon, KubeArmor, Falco)
  BPF BPF_SYSCALL BPF_JIT NET_CLS_BPF NET_ACT_BPF NET_SCH_INGRESS
  DEBUG_INFO_BTF BPF_LSM
)

# Entries that must appear in the default LSM list (active without boot params).
REQUIRED_LSM=(bpf)

missing=0

for opt in "${REQUIRED[@]}"; do
  if grep -Eq "^CONFIG_${opt}=(y|m)$" "${CONFIG_FILE}"; then
    echo "  ok       CONFIG_${opt}"
  else
    echo "  MISSING  CONFIG_${opt}"
    missing=$((missing + 1))
  fi
done

lsm_list=$(sed -n 's/^CONFIG_LSM="\(.*\)"$/\1/p' "${CONFIG_FILE}")
for lsm in "${REQUIRED_LSM[@]}"; do
  if [[ ",${lsm_list}," == *",${lsm},"* ]]; then
    echo "  ok       CONFIG_LSM contains ${lsm}"
  else
    echo "  MISSING  CONFIG_LSM contains ${lsm} (current: \"${lsm_list}\")"
    missing=$((missing + 1))
  fi
done

if [ "${missing}" -ne 0 ]; then
  echo "${missing} Kubernetes-required kernel option(s) missing in ${CONFIG_FILE}" >&2
  exit 1
fi

echo "All Kubernetes-required kernel options are present."
