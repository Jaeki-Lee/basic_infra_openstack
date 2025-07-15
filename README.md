# OpenStack 3-Tier 웹 아키텍처 (Terraform)

이 프로젝트는 Terraform을 사용하여 OpenStack 클라우드 환경에 기본적인 3-Tier 웹 아키텍처를 배포합니다.

## 아키텍처

배포되는 인프라의 구조는 다음과 같습니다.

```
[ External Network ]
       |
       | (Floating IP)
+------V------+      +-------------+      +-------------+      +-------------+
|   Bastion   |      |   HAProxy   |      |    Web 1    |      |    Web 2    |
| (bastion2)  |      |  (haproxy2) |      |    (web3)   |      |    (web4)   |
+-------------+      +-------------+      +-------------+      +-------------+
       | (SSH)              | (HTTP)             |                    |
       |                    |                    |                    |
+------V--------------------V--------------------V--------------------V------+
|                                Private Network                               |
|  - private4 (172.16.4.0/24) for Bastion                                      |
|  - private5 (172.16.5.0/24) for HAProxy                                      |
|  - private6 (172.16.6.0/24) for Web Servers                                  |
+------------------------------------------------------------------------------+
```

**구성 요소:**
*   **Bastion Host**: 외부에서 내부망 서버에 안전하게 접근하기 위한 SSH 점프 호스트입니다.
*   **HAProxy**: 두 대의 웹 서버로 들어오는 HTTP 트래픽을 분산하는 로드 밸런서입니다.
*   **Web Servers**: Nginx가 설치된 두 대의 웹 서버입니다.
*   **Networking**: 3개의 사설 네트워크와 외부 통신을 위한 라우터로 구성됩니다.
*   **Security Groups**: 각 티어에 필요한 최소한의 포트(SSH, HTTP, ICMP)만 허용하도록 설정됩니다.

## 사전 준비 사항

1.  **Terraform**: Terraform (버전 0.13 이상)이 설치되어 있어야 합니다.
2.  **OpenStack Credentials**: OpenStack에 접근하기 위한 인증 정보가 필요합니다. `provider.tf` 파일에 직접 입력하거나 환경 변수로 설정할 수 있습니다.
3.  **SSH Keypair**: OpenStack에 미리 생성된 SSH 키페어가 있어야 하며, 해당 키페어의 개인 키 파일을 가지고 있어야 합니다.

## 설정

배포 전, `value.tf` 파일의 변수들을 환경에 맞게 수정하거나 `terraform.tfvars` 파일을 생성하여 값을 지정할 수 있습니다.

**주요 변수:**
*   `flavor`: 인스턴스에 사용할 Flavor (예: "2").
*   `image_id`: 인스턴스 부팅에 사용할 이미지의 ID (예: "829a7888-b7ee-4022-bc20-75f0f444f607").
*   `volume_size`: 각 인스턴스의 루트 볼륨 크기 (GB).
*   `keypair`: 인스턴스에 주입할 OpenStack 키페어의 이름 (예: "myk8skey").
*   `private_key_path`: `keypair`에 해당하는 로컬 SSH 개인 키 파일의 절대 경로 (예: "/root/.ssh/myk8skey.pem").

**예시 `terraform.tfvars` 파일:**
```hcl
flavor           = "2"
image_id         = "829a7888-b7ee-4022-bc20-75f0f444f607"
keypair          = "myk8skey"
private_key_path = "/root/.ssh/myk8skey.pem"
```

## 사용법

1.  **Terraform 초기화**
    Terraform 백엔드와 프로바이더를 초기화합니다.
    ```bash
    terraform init
    ```

2.  **실행 계획 검토**
    인프라 변경 사항을 미리 확인합니다.
    ```bash
    terraform plan
    ```

3.  **인프라 배포**
    계획을 적용하여 인프라를 생성합니다.
    ```bash
    terraform apply
    ```

4.  **인프라 삭제**
    생성된 모든 리소스를 삭제합니다.
    ```bash
    terraform destroy
    ```

## 결과물 (Outputs)

배포가 완료되면 `terraform output` 명령어를 통해 주요 리소스의 정보를 확인할 수 있습니다. (현재 `outputs.tf` 파일이 비어있으므로, 필요 시 인스턴스의 Floating IP 등을 출력하도록 추가하는 것을 권장합니다.)

**`outputs.tf` 추천 내용:**
```hcl
output "bastion_fip" {
  description = "Bastion Host Floating IP"
  value       = openstack_compute_floatingip_associate_v2.fip_bastion.floating_ip
}

output "haproxy_fip" {
  description = "HAProxy Floating IP"
  value       = openstack_compute_floatingip_associate_v2.fip_haproxy.floating_ip
}
```
