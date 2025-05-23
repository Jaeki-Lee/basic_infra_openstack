#!/usr/bin/env bash
# OpenStack 볼륨 일괄 정리 스크립트
# Usage:
#   source ~/openrc                   # 0. OpenStack 명령어 환경 로드
#   ./cleanup_volumes.sh vol1 vol2 ...

set -euo pipefail

# OpenStack RC 파일이 로드되었는지 확인
if [ -z "${OS_PROJECT_NAME:-}" ]; then
  echo "ERROR: Please source your OpenStack RC file (e.g., source ~/openrc)"
  exit 1
fi

# 입력된 볼륨 이름 목록
volume_names=( "$@" )
if [ "${#volume_names[@]}" -eq 0 ]; then
  echo "Usage: $0 <volume_name1> [volume_name2 ...]"
  exit 1
fi

echo "Starting volume cleanup for: ${volume_names[*]}"

for vol_name in "${volume_names[@]}"; do
  echo -e "\nProcessing volume: $vol_name"

  # 2.1. 볼륨 ID 조회
  vol_id=$(openstack volume list --name "$vol_name" -f value -c ID)
  if [ -z "$vol_id" ]; then
    echo "  [WARNING] Volume '$vol_name' not found"
    continue
  fi
  echo "  ID: $vol_id"

  # 2.2. attachment ID 조회 (0번째)
  att_id=$(openstack volume attachment list --volume "$vol_id" -f value -c ID | head -n1 || true)
  if [ -n "$att_id" ]; then
    echo "  Detaching attachment: $att_id"
    # 마이크로버전 필요 시 --os-volume-api-version 3.27
    openstack --os-volume-api-version 3.27 volume attachment delete "$att_id" \
      && echo "    [OK] Detached $att_id" \
      || echo "    [ERROR] Failed to detach $att_id"
  else
    echo "  [INFO] No attachments found for $vol_name"
  fi

  # 2.3. 볼륨 삭제
  echo "  Deleting volume: $vol_name ($vol_id)"
  openstack volume delete --force "$vol_id" \
    && echo "    [OK] Deleted $vol_name ($vol_id)" \
    || echo "    [ERROR] Failed to delete $vol_id"
done

echo "\nAll done."
