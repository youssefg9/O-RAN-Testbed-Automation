# Blueprint for Deploying 5G O-RAN Testbeds: A Guide to Using Diverse O-RAN Software Stacks
---

## Abstract

This documentation serves as a blueprint for new researchers, offering a comprehensive guide on establishing an Open Radio Access Network (O-RAN) testbed from scratch. It details the O-RAN architecture and the supporting software stacks required for each component, and provides both aggregated and disaggregated deployment scenarios tested on our testbeds. The guide provides thorough installation instructions for each software stack we tested. In addition, a testbed example of a disaggregated scenario is used to demonstrate proper configurations and practical operations to test the connection and interoperation between the deployed O-RAN components. Moreover, this documentation introduces our innovative automation tool, designed to streamline the installation and configuration of some O-RAN components, ensuring a more efficient deployment process. This publication aims to equip researchers with the foundational knowledge and practical steps needed to initiate and manage their own O-RAN testbeds effectively.

**Keywords:** 5G New Radio; FlexRIC; O-RAN SC Near-RT RIC; Open RAN; Open5GS; srsRAN 4G; srsRAN Project; Testbed; USRP.

---

## Table of Contents

- [Abbreviations](#abbreviations)
- [1. Introduction](#1-introduction)
  - [1.1. O-RAN Architecture](#11-o-ran-architecture)
  - [1.2. Software Stacks for O-RAN Components](#12-software-stacks-for-o-ran-components)
- [2. System Requirements](#2-system-requirements)
  - [2.1. Software](#21-software)
  - [2.2. Hardware and System Prerequisites](#22-hardware-and-system-prerequisites)
- [3. RAN Components](#3-ran-components)
  - [3.1. gNodeB: srsRAN Project Setup](#31-gnodeb-srsran-project-setup)
  - [3.2. 5G UE: srsRAN 4G](#32-5g-ue-srsran-4g)
  - [3.3. E2 Simulator](#33-e2-simulator)
- [4. 5G Core](#4-5g-core)
  - [4.1. Installation with Package Manager](#41-installation-with-package-manager)
  - [4.2. Configuration](#42-configuration)
  - [4.3. Installation from Sources](#43-installation-from-sources)
  - [4.4. Installation with Docker](#44-installation-with-docker)
- [5. Near-RT RIC](#5-near-rt-ric)
  - [5.1. FlexRIC Setup](#51-flexric-setup)
  - [5.2. OSC Near-RT RIC Setup](#52-osc-near-rt-ric-setup)
- [6. Testbed Deployments](#6-testbed-deployments)
  - [6.1. Aggregated Deployments](#61-aggregated-deployments)
  - [6.2. Disaggregated Deployments](#62-disaggregated-deployments)
- [7. Automation Tool](#7-automation-tool)
- [8. Test Setup](#8-test-setup)
  - [8.1. Testbed](#81-testbed)
  - [8.2. Scripts and Configurations](#82-scripts-and-configurations)
  - [8.3. Running Testbed](#83-running-testbed)
  - [8.4. Tests](#84-tests)
- [9. Conclusion and Future Work](#9-conclusion-and-future-work)
- [References](#references)

---

## Abbreviations

| Abbreviation | Full Form |
|---|---|
| 3GPP | The Third Generation Partnership Project |
| AMF | Access and Mobility Management Function |
| CLI | Command Line Interface |
| CPU | Central Processing Unit |
| DL | Downlink |
| E2AP | E2 Application Protocol |
| E2SM | E2 Service Model |
| E2SM-KPM | E2 Service Model - Key Performance Measurement |
| FDD | Frequency Division Duplex |
| GTP-U | GPRS Tunneling Protocol User Plane |
| HSS | Home Subscriber Server |
| IP | Internet Protocol |
| LTE | Long Term Evolution |
| ML | Machine Learning |
| NAT | Network Address Translation |
| near-RT RIC | Near-real-time RAN intelligent controller |
| NF | Network Function |
| NGAP | Next Generation Application Protocol |
| non-RT RIC | Non-real-time RAN intelligent controller |
| NR | New Radio |
| NRF | Network Repository Function |
| O-CU | O-RAN Central Unit |
| O-DU | O-RAN Distributed Unit |
| O-RAN | Open Radio Access Network |
| O-RU | O-RAN Radio Unit |
| OAI | OpenAirInterface |
| OS | Operating System |
| OSC | O-RAN Software Community |
| PCF | Policy Control Function |
| PCRF | Policy and Charging Rules Function |
| PLMN | Public Land Mobile Network |
| PPS | Pulse Per Second |
| RAN | Radio Access Network |
| RF | Radio Frequency |
| RIC | RAN Intelligent Controller |
| RRM | Radio Resource Management |
| RSRP | Reference Signal Receive Power |
| RX | Receiver |
| SA | Standalone |
| SCTP | Stream Control Transmission Protocol |
| SMO | Service Management and Orchestration |
| TX | Transmitter |
| UDR | Unified Data Repository |
| UE | User Equipment |
| UL | Uplink |
| UPF | User Plane Function |
| USIM | Universal Subscriber Identity Module |
| USRP | Universal Software Radio Peripheral |
| VM | Virtual Machine |
| ZMQ | Zero Message Queue |

---

## 1. Introduction

Before the advent of Open Radio Access Network (O-RAN), Radio Access Networks (RANs) were typically dominated by proprietary, monolithic systems from individual vendors. This often resulted in high costs and limited flexibility. O-RAN addresses these challenges through open standards that enable interoperability between components from different vendors while adhering to the specifications defined by 3GPP.

In advancing O-RAN research and implementation, the development of testbeds is crucial. These testbeds provide controlled and replicable environments for validating and enhancing O-RAN technologies and network performance. They serve as platforms to test various deployment scenarios, assess interoperability between O-RAN components and software stacks from different vendors, and evaluate research outcomes for specific O-RAN tasks. Testbeds offer invaluable insights for large-scale deployments, ensuring that O-RAN solutions are robust, efficient, and ready for real-world applications.

### 1.1. O-RAN Architecture

The O-RAN architecture was defined by O-RAN Alliance in [1]. Its key elements include:

- **Service Management and Orchestration (SMO):** Responsible for RAN domain management.
- **non-RT RIC:** Runs in SMO and provides intelligent RAN optimization with service and policy management, ML model management, and enrichment information for near-RT RIC functions. The response interval is greater than 1 s. It provides rApps to realize the functionality.
- **near-RT RIC:** Controls the E2 nodes (O-CU, O-DU) with a response time between 10 ms and 1 s. The control is steered via the policies and enrichment data from non-RT RIC. Radio Resource Management (RRM) is a main function provided by near-RT RIC and is realized by means of E2 Service Models (E2SMs) on near-RT RIC Applications (xApps).
- **O-CU, O-DU, and O-RU:** The gNB functions defined by 3GPP are disaggregated and distributed into these O-RAN components.

In addition, **O-Cloud** provides a cloud computing platform that can host some of the O-RAN Network Functions (NFs).

Key interfaces:

- **A1 Interface:** Exchanges information between non-RT and near-RT RICs to support policy management, enrichment information, and ML model management.
- **O1 Interface:** Connects SMO with near-RT RIC and E2 nodes for NF management and orchestration.
- **E2 Interface:** Connects near-RT RIC with E2 nodes and provides near-RT services using E2AP and E2SMs.

### 1.2. Software Stacks for O-RAN Components

**non-RT RIC:**
- non-RT RIC from OSC — provides both non-RT RIC framework and rApps. Deployed in Kubernetes containers.

**near-RT RIC:**
- near-RT RIC from OSC — provides both near-RT RIC framework and xApps. Deployed in Kubernetes clusters.
- FlexRIC — provides both near-RT RIC framework and xApps. Deployed on bare metal server/workstation or VM.
- near-RT RIC from SRS — built on Release I of OSC near-RT RIC to support quick deployment and control over srsRAN gNB with xApps programmed in Python. Deployed in a docker container.

**E2 Nodes and User Equipments (UEs):**
- **OpenAirInterface (OAI):** Supports CU/DU split, E2 connection to near-RT RIC, and connection to OAI UEs. Supports Split 7.2 fronthaul interfaces to RUs, and some implementations support Split 8. Deployed on bare metal or Kubernetes clusters.
- **srsRAN:** Includes srsRAN Project for 5G O-RAN gNB, and srsRAN 4G for 5G UE. Supports CU/DU split, E2 connection to near-RT RIC, and Split 7.2 and Split 8 fronthaul interfaces. Deployable on Kubernetes, docker, bare metal, or VM.

**5G Core Network:** Open5GS, Free5GC, Open5GCore, OAI 5G CN, etc.

---

## 2. System Requirements

### 2.1. Software

- **5G gNB:** srsRAN Project
- **5G UE:** srsUE from srsRAN 4G
- **5G Core:** Open5GS
- **RIC:** FlexRIC and OSC near-RT RIC

> **Note:** srsRAN 4G supports 5G Standalone (SA) in srsUE by modifying the srsUE configuration file.

### 2.2. Hardware and System Prerequisites

**USRPs:** Ettus B210 and X310 for gNB; Ettus B210 for srsUE. USRPs share the same PPS time source and 10 MHz frequency source from an octoclock.

**CPUs tested:**
- Intel Xeon Gold 6246R — 16 cores @ 3.4 GHz
- Intel Xeon Gold 6334 — 8 cores @ 3.6 GHz
- Intel Core i9-12900K — 16 cores @ 2.4 GHz

**Operating System:** OSC near-RT RIC can operate on Ubuntu 20.04 (preferred) or Ubuntu 22.04. Other software is installed on Ubuntu 22.04.

#### Low-latency Kernel

```bash
sudo apt-get -y install linux-lowlatency
```

After rebooting, verify:

```bash
uname -r
# Expected: 5.15.0-102-lowlatency
```

#### Power Management

1. In `/etc/default/grub`, disable c-state:

   ```
   GRUB_CMDLINE_LINUX_DEFAULT="quiet processor.max_cstate=1 intel_idle.max_cstate=0 idle=poll"
   ```

   Then:

   ```bash
   sudo update-grub2
   ```

2. In `/etc/modprobe.d/blacklist.conf`, add:

   ```
   blacklist intel_powerclamp
   ```

   Then reboot.

3. **BIOS Settings:**
   - Disable secure booting option
   - Disable hyperthreading
   - Enable virtualization
   - Disable c-state power management functions
   - Enable real-time tuning and Intel Turbo boost

4. Set the scaling governor to performance:

   ```bash
   sudo apt-get install cpufrequtils
   ```

   Add to `/etc/default/cpufrequtils`:

   ```
   GOVERNOR="performance"
   ```

   Then:

   ```bash
   sudo systemctl disable ondemand.service
   sudo /etc/init.d/cpufrequtils restart
   ```

5. Verify with i7z:

   ```bash
   sudo apt install i7z
   sudo i7z
   ```

   All cores should have C0 % as 100 and Halt(C1) % as 0.

#### SCTP

```bash
sudo apt install libsctp-dev
```

Check if SCTP is enabled:

```bash
lsmod | grep 'sctp'
```

If nothing is returned, comment out the lines in `/etc/modprobe.d/sctp.conf`:

```
#install sctp /bin/true
```

And load:

```bash
sudo modprobe sctp
```

#### ZMQ and UHD

```bash
sudo apt-get install libzmq3-dev libuhd-dev uhd-host
sudo uhd_images_downloader
```

---

## 3. RAN Components

### 3.1. gNodeB: srsRAN Project Setup

#### 3.1.1. Installation

Tested on srsRAN Project versions 23.5 and 23.10, and version 23.10.1 with updates until 12/22/2023.

Install dependencies:

```bash
sudo apt-get install cmake make gcc g++ pkg-config libfftw3-dev \
    libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev
```

Clone and build:

```bash
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
```

During cmake, verify ZMQ is found:

```
-- FINDING ZEROMQ.
-- Checking for module 'ZeroMQ'
--   No package 'ZeroMQ' found
-- Found libZEROMQ: /usr/local/include, /usr/local/lib/libzmq.so
```

Then build and install:

```bash
make -j $(nproc)
make test -j $(nproc)
sudo make install
```

#### 3.1.2. Configuration

**AMF Connection:**

```yaml
amf:
    addr: <5G_core_bind_address>
    bind_addr: <gNB_bind_address>
```

**RF Front-end — Ettus B210:**

```yaml
ru_sdr:
    device_driver: uhd
    device_args: type=b200
    clock: external
    sync: external
    srate: 11.52
    tx_gain: 75
    rx_gain: 35
```

**RF Front-end — Ettus X310:**

```yaml
ru_sdr:
    device_driver: uhd
    device_args: type=x300,addr=<x310_ip_addr>,dboard_clock_rate=11.52e6,time_source=external,clock_source=external
    clock: external
    sync: external
    srate: 11.52
    tx_gain: 30
    rx_gain: 5
```

**RF Front-end — ZMQ:**

```yaml
ru_sdr:
    device_driver: zmq
    device_args: tx_port=tcp://<tx_ip>:<tx_port>,rx_port=tcp://<rx_ip>:<rx_port>,base_srate=11.52e6
    srate: 11.52
    tx_gain: 75
    rx_gain: 35
```

**5G Cell Configuration:**

```yaml
cell_cfg:
    dl_arfcn: 368500
    band: 3
    channel_bandwidth_MHz: 10
    common_scs: 15
    plmn: "00101"
    tac: 7
    pdcch:
        dedicated:
            ss2_type: common
            dci_format_0_1_and_1_1: false
        common:
            ss0_index: 0
            coreset0_index: 6
    prach:
        prach_config_index: 1
```

> **Important:** `tac` and `plmn` should align with those in AMF of Open5GS.

**RIC Connection:**

```yaml
e2:
    enable_du_e2: true
    addr: <RIC_bind_address>
    bind_addr: <gNB_bind_address_for_RIC>
    e2sm_kpm_enabled: true
```

**E2AP Packet Captures:**

```yaml
pcap:
    e2ap_enable: true
    e2ap_filename: /tmp/gnb_e2ap.pcap
```

### 3.2. 5G UE: srsRAN 4G

#### 3.2.1. Installation

Install dependencies:

```bash
sudo apt-get install build-essential cmake libfftw3-dev libmbedtls-dev \
    libboost-program-options-dev libconfig++-dev libsctp-dev
```

Clone and build:

```bash
git clone https://github.com/srsRAN/srsRAN_4G.git
cd srsRAN_4G
mkdir build
cd build
cmake ../
```

Verify ZMQ is found during cmake (same output as Section 3.1.1).

```bash
make
make test
sudo make install
srsran_install_configs.sh user
```

#### 3.2.2. Configuration

Based on the script in [8]. When ZMQ is used:

```ini
device_name = zmq
device_args = tx_port=tcp://<tx_ip>:<tx_port>,rx_port=tcp://<rx_ip>:<rx_port>,base_srate=11.52e6
```

### 3.3. E2 Simulator

The E2 simulator from OSC's E2 simulator repository can be used to test the E2 interface on the installed OSC near-RT RIC.

#### 3.3.1. Build and Installation

```bash
git clone https://gerrit.o-ran-sc.org/r/sim/e2-interface
apt-get install cmake g++ libsctp-dev
cd e2-interface/e2sim
vi Dockerfile_kpm  # modify last line to "CMD sleep 100000000"
mkdir build
cd build
cmake .. && make package && cmake .. -DDEV_PKG=1 && make package
cp *.deb ../e2sm_examples/kpm_e2sm/
cd ../
docker build -t oransim:0.0.999 . -f Dockerfile_kpm
```

Run the container:

```bash
docker run -d -it --name oransim oransim:0.0.999
```

#### 3.3.2. Running E2 Simulator

Find the E2 termination SCTP IP:

```bash
kubectl get svc -n ricplt | grep e2term-sctp
# ricplt service-ricplt-e2term-sctp-alpha NodePort 10.96.147.226 sctp-alpha:36422→32222/SCTP
```

Execute:

```bash
docker exec -it oransim /bin/bash
kpm_sim 10.96.147.226 36422
```

Expected output includes:

```
[E2AP] Received SETUP-RESPONSE-SUCCESS
```

#### 3.3.3. E2 Connection Check from RIC Cluster

```bash
kubectl get service -n ricplt | grep service-ricplt-e2mgr-http
# ricplt service-ricplt-e2mgr-http ClusterIP 10.96.90.98 http:3800→0

curl -X GET http://10.96.90.98:3800/v1/nodeb/states 2>/dev/null | jq
```

Expected output:

```json
[
  {
    "inventoryName": "gnb_734_373_16b8cef1",
    "globalNbId": {
      "plmnId": "373437",
      "nbId": "10110101110001100111011110001"
    },
    "connectionStatus": "CONNECTED"
  }
]
```

---

## 4. 5G Core

We utilize Open5GS to deliver 5G Core network functionalities. Open5GS can be installed with a package manager, built from sources [9], or using Docker [10].

**Compatibility:**
- Open5GS v2.6.4 and v2.6.6 — compatible with srsRAN Project v23.5 and v23.10
- Open5GS v2.7.0 — supports srsRAN Project v23.10.1 with additional required steps
- Dockerized Open5GS from srsRAN Project — tested with all three srsRAN versions

### 4.1. Installation with Package Manager

#### 4.1.1. MongoDB

```bash
sudo apt update
sudo apt install gnupg
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] \
    https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod
```

#### 4.1.2. Open5GS

```bash
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install open5gs
```

#### 4.1.3. WebUI

Install Nodejs:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/nodesource.gpg] \
    https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | \
    sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install nodejs -y
```

Install WebUI:

```bash
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```

### 4.2. Configuration

#### 4.2.1. AMF and UPF Configurations in 5G SA Mode

In `/etc/open5gs/amf.yaml`:

```yaml
ngap:
    - addr: 127.0.0.5
guami:
    - plmn_id:
        mcc: 001
        mnc: 01
tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 7
plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
```

In `/etc/open5gs/upf.yaml`:

```yaml
gtpu:
    - addr: 127.0.0.5
```

Restart:

```bash
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-upfd
```

#### 4.2.2. NRF Configurations in Open5GS v2.7.0

In `/etc/open5gs/nrf.yaml`:

```yaml
nrf:
    serving:
        - plmn_id:
            mcc: 001
            mnc: 01
```

#### 4.2.3. Register Subscriber

Default subscriber information from srsRAN Project:

| Parameter | Value |
|---|---|
| opc | `63BFA50EE6523365FF14C1F45F88737D` |
| k | `00112233445566778899aabbccddeeff` |
| imsi | `001010123456780` |
| apn | `srsapn` |
| apn_protocol | `ipv4` |

Open a web browser at `http://localhost:3000` (port `9999` for Open5GS v2.7.0). Login with Username `admin` and Password `1423`. Click the + button to create a subscriber.

#### 4.2.4. Enable UE Access to Internet

```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE
```

> **Note:** These rules reset on reboot unless saved with `iptables-save`.

Disable firewall:

```bash
sudo ufw disable
```

### 4.3. Installation from Sources

#### 4.3.1. MongoDB

Follow the instructions in [Section 4.1.1](#411-mongodb).

#### 4.3.2. TUN Device

```bash
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip addr add 2001:db8:cafe::1/48 dev ogstun
sudo ip link set ogstun up
```

> **Note:** IP addresses need to be reconfigured after each reboot.

#### 4.3.3. Open5GS

Install dependencies:

```bash
sudo apt install python3-pip python3-setuptools python3-wheel ninja-build \
    build-essential flex bison git cmake libsctp-dev libgnutls28-dev \
    libgcrypt20-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev \
    libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libnghttp2-dev libtins-dev libtalloc-dev meson
```

Clone and build:

```bash
git clone https://github.com/open5gs/open5gs
cd open5gs
meson build --prefix=$(pwd)/install
ninja -C build
```

Verify:

```bash
./build/tests/registration/registration
cd build
meson test -v
```

Install:

```bash
ninja install
cd ..
```

**Running NFs together** using `build/configs/sample.yaml` (modify `amf` and `upf` sections per [Section 4.2.1](#421-amf-and-upf-configurations-in-5g-sa-mode)):

```bash
./build/tests/app/5gc
```

#### 4.3.4. WebUI

In the open5gs directory:

```bash
cd webui
npm ci
npm run dev
```

#### 4.3.5. Register Subscriber

Follow [Section 4.2.3](#423-register-subscriber).

#### 4.3.6. Enable UE Access to Internet

Follow [Section 4.2.4](#424-enable-ue-access-to-internet).

### 4.4. Installation with Docker

The dockerized Open5GS provided by srsRAN Project uses Open5GS v2.6.1 with default AMF IP address `10.53.1.2`.

```bash
sudo apt install docker-compose
sudo gpasswd -a $USER docker
newgrp docker
cd docker
docker-compose up --build 5gc
```

#### 4.4.1. Access Dockerized Open5GS from gNB

Update gNB configuration: replace `amf: addr` with `10.53.1.2`. IP rules may need to be added on the gNB server.

#### 4.4.2. Enable UE access to Internet

```bash
docker exec -t open5gs_5gc /bin/bash
```

Then follow [Section 4.2.4](#424-enable-ue-access-to-internet).

---

## 5. Near-RT RIC

### 5.1. FlexRIC Setup

#### 5.1.1. FlexRIC Installation for srsRAN Project v23.10.1

Install dependencies for SWIG and FlexRIC:

```bash
sudo apt install autotools-dev automake libpcre2-dev bison byacc
sudo apt install libsctp-dev python3.8 cmake-curses-gui libpcre2-dev python3-dev gcc-10 g++-10
```

Install SWIG v4.1+:

```bash
git clone https://github.com/swig/swig.git
cd swig
git checkout release-4.1
./autogen.sh
./configure --prefix=/usr/
make -j$(nproc)
sudo make install
```

Clone and build FlexRIC:

```bash
git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git
git checkout master
cd flexric
mkdir build
```

Configure FlexRIC IP in `flexric/flexric.conf` (or after install at `/usr/local/etc/flexric/flexric.conf`):

```ini
[NEAR-RIC]
NEAR_RIC_IP = 192.168.10.2  # Example IP
```

Build with gcc-10, E2AP v3, and KPM v3:

```bash
cd build
CC=gcc-10 CXX=g++-10 cmake .. -DE2AP_VERSION=E2AP_V3 -DKPM_VERSION=KPM_V3_00
sudo make install
cd ..
```

#### 5.1.2. FlexRIC Installation for srsRAN Project v23.5 and v23.10

Install dependencies:

```bash
sudo apt-get update
sudo apt-get install swig libsctp-dev cmake-curses-gui libpcre2-dev python3 python3-dev
```

Download the patch file from `https://docs.srsran.com/projects/project/en/latest/_downloads/d0bb1100d471824e1f5536ddd0765d0d/flexric.patch`.

```bash
git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git
cd flexric
git checkout e2ap-v2
git apply -v ./flexric.patch
mkdir build
cd build
CC=gcc-10 CXX=g++-10 cmake ../
make
sudo make install
```

### 5.2. OSC Near-RT RIC Setup

#### 5.2.1. Software Source and Dependency

```bash
sudo apt install git
git clone "https://gerrit.o-ran-sc.org/r/ric-plt/ric-dep" -b j-release
```

#### 5.2.2. Kubernetes, Docker, Helm Chart Installation

```bash
cd ric-dep/bin
./install_k8s_and_helm.sh
```

Verify:

```bash
kubectl get po -A
```

All components should show `Running` status.

#### 5.2.3. Modify Service Platform Configuration File

In `ric-dep/RECIPE_EXAMPLE/example_recipe_latest_stable.yaml`:

```yaml
extsvcplt:
    riccp: "<host_node_real_IP>"
    auxip: "<host_node_real_IP>"
```

#### 5.2.4. Install Common Template to Helm

```bash
cd ric-dep/bin
./install_common_templates_to_helm.sh
```

#### 5.2.5. Installing Near RT-RIC

```bash
./install -f ../RECIPE_EXAMPLE/example_recipe_latest_stable.yaml
```

Verify:

```bash
kubectl get pods -A
```

All RIC pods should be `Running`.

#### 5.2.6. RIC Application, xApps

##### 5.2.6.1. Onboarding of xApp Using dms_cli tool

`dms_cli` offers command line utilities to onboard xApps to chartmuseum.

##### 5.2.6.2. Chartmuseum

```bash
docker run --rm -u 0 -it -d -p 8090:8080 -e DEBUG=1 -e STORAGE=local \
    -e STORAGE_LOCAL_ROOTDIR=/charts -v $(pwd)/charts:/charts \
    chartmuseum/chartmuseum:latest
```

Set environment variable:

```bash
export CHART_REPO_URL=http://0.0.0.0:8090
```

##### 5.2.6.3. Onboarder (dms_cli) Installation

```bash
git clone "https://gerrit.o-ran-sc.org/r/ric-plt/appmgr"
cd appmgr/xapp_orchestrater/dev/xapp_onboarder
apt install python3-pip
pip3 uninstall xapp_onboarder   # if already installed
pip3 install ./
chmod 755 /usr/local/bin/dms_cli
```

Health check:

```bash
dms_cli health
# Expected: True
```

##### 5.2.6.4. hw-go xApp Build and Preparation

```bash
git clone https://gerrit.o-ran-sc.org/r/ric-app/hw-go
cd hw-go
docker build -t example.com:80/hw-go:1.2 .
export CHART_REPO_URL=http://0.0.0.0:8090
```

Edit `config/config-file.json`:
1. Set `tag` = `1.2` under `containers.image`
2. Set `registry` = `example.com:80` under `containers.image`
3. Set `name` = `hw-go` under `containers.image`

```bash
docker save -o hw-go.tar example.com:80/hw-go:1.2
ctr -n=k8s.io image import hw-go.tar
```

##### 5.2.6.5. Onboarding hw-go xApp and Install

```bash
dms_cli onboard ./config/config-file.json ./config/schema.json
dms_cli install hw-go 1.0.0 ricxapp
```

To uninstall:

```bash
dms_cli uninstall hw-go ricxapp
```

##### 5.2.6.6. Checking xApp's Deployment Status

```bash
kubectl get services -n ricplt | grep service-ricplt-appmgr
curl http://service-ricplt-appmgr-http.ricplt:8080/ric/v1/xapps | jq .
```

Check pod status:

```bash
kubectl get po -n ricxapp
```

#### 5.2.7. Interoperation with E2 Simulator

When the xApp is connected to the RIC cluster, xApp's initial configuration message, xApp register, and subscription request message will be transferred to the E2 simulator through the E2 functions in the cluster pods. The subscription request uses `RICsubscriptionRequest` with E2AP protocol.

---

## 6. Testbed Deployments

**Common RAN configurations used across all deployments:**
- Frequency band: n3
- Duplexing method: FDD
- Uplink center frequency: 1747.5 MHz
- Downlink center frequency: 1842.5 MHz
- Bandwidth: 10 MHz

### 6.1. Aggregated Deployments

In aggregated scenarios, the 5G Core, near-RT RIC, and gNB are on the same server. UE may be on the same or different server.

Default IP addresses for aggregated scenarios with FlexRIC:
- Open5GS: `127.0.0.5`
- FlexRIC: `127.0.0.1`
- srsRAN gNB: `127.0.0.1`

#### 6.1.1. Single Bare Metal Server, ZMQ Connection

All components on one server. Installation guide:

| Software | Installation Guide | Server |
|---|---|---|
| srsRAN gNB | Section 3.1 | Server 1 |
| srsUE | Section 3.2 | Server 1 |
| FlexRIC | Section 5.1.1 or 5.1.2 | Server 1 |
| Open5GS | Section 4.1 or 4.3 | Server 1 |

**gNB AMF config:**

```yaml
amf:
    addr: 127.0.0.5
    bind_addr: 127.0.0.1
```

**gNB E2 config:**

```yaml
e2:
    enable_du_e2: true
    addr: 127.0.0.1
    bind_addr: 127.0.0.1
    e2sm_kpm_enabled: true
```

**gNB ZMQ config** (TX via `127.0.0.1:2000`, RX from `127.0.0.1:2001`):

```yaml
ru_sdr:
    device_driver: zmq
    device_args: tx_port=tcp://127.0.0.1:2000,rx_port=tcp://127.0.0.1:2001,base_srate=11.52e6
    srate: 11.52
    tx_gain: 75
    rx_gain: 35
```

**UE ZMQ config:**

```ini
device_name = zmq
device_args = tx_port=tcp://127.0.0.1:2001,rx_port=tcp://127.0.0.1:2000,base_srate=11.52e6
```

#### 6.1.2. Two Servers, ZMQ or USRP Connections

UE on Server 1; gNB, Open5GS, FlexRIC on Server 2.

| Software | Installation Guide | Server |
|---|---|---|
| srsRAN gNB | Section 3.1 | Server 2 |
| srsUE | Section 3.2 | Server 1 |
| FlexRIC | Section 5.1.1 or 5.1.2 | Server 2 |
| Open5GS | Section 4.1 or 4.3 | Server 2 |

##### 6.1.2.1. ZMQ Connection

Subnet `192.0.13.x` used for inter-server ZMQ connection.

**gNB on Server 2** (TX: `192.0.13.2:2000`, RX from: `192.0.13.1:2001`):

```yaml
ru_sdr:
    device_driver: zmq
    device_args: tx_port=tcp://192.0.13.2:2000,rx_port=tcp://192.0.13.1:2001,base_srate=11.52e6
    srate: 11.52
    tx_gain: 75
    rx_gain: 35
```

**UE on Server 1:**

```ini
device_name = zmq
device_args = tx_port=tcp://192.0.13.1:2001,rx_port=tcp://192.0.13.2:2000,base_srate=11.52e6
```

##### 6.1.2.2. USRP Connection

50 dB attenuation between TX and RX ports.

**gNB:**

```yaml
ru_sdr:
    device_driver: uhd
    device_args: type=b200
    clock: external
    sync: external
    srate: 11.52
    tx_gain: 75
    rx_gain: 35
```

**UE:**

```ini
[rf]
freq_offset = 0
tx_gain = 80
rx_gain = 35
srate = 11.52e6
nof_antennas = 1
device_name = uhd
device_args = clock=external
time_adv_nsamples = 300
```

#### 6.1.3. Single Server, Multiple UEs and One gNB, ZMQ Connection

Install per [Section 6.1.1](#611-single-bare-metal-server-zmq-connection). Uses GNURadio channel model: UE TX samples are summed and sent to gNB RX; gNB TX is duplicated to each UE.

Each UE is isolated in its own network namespace with a unique USIM.

**UE Configuration Table:**

| Parameter | UE1 | UE2 | UE3 |
|---|---|---|---|
| OPc | `63bfa50ee6523365ff14c1f45f88737d` | same | same |
| K | `00112233445566778899aabbccddeeff` | `...f00` | `...f01` |
| IMSI | `001010123456780` | `...90` | `...91` |
| IMEI | `353490069873319` | `...8` | `...2` |
| netns | `ue1` | `ue2` | `ue3` |
| TX Port | `2101` | `2201` | `2301` |
| RX Port | `2100` | `2200` | `2300` |

**UE1 configuration example:**

```ini
[rf]
device_name = zmq
device_args = tx_port=tcp://127.0.0.1:2101,rx_port=tcp://127.0.0.1:2100,base_srate=11.52e6

[pcap]
enable = none
mac_filename = /tmp/ue1_mac.pcap
mac_nr_filename = /tmp/ue1_mac_nr.pcap
nas_filename = /tmp/ue1_nas.pcap

[log]
filename = /tmp/ue1.log

[usim]
mode = soft
algo = milenage
opc = 63BFA50EE6523365FF14C1F45F88737D
k = 00112233445566778899aabbccddeeff
imsi = 001010123456780
imei = 353490069873319

[gw]
netns = ue1
ip_devname = tun_srsue
ip_netmask = 255.255.255.0
```

#### 6.1.4. Kubernetes OSC Near-RT RIC, Containerized Open5GS, E2 Simulator, ZMQ

| Software | Installation Guide | Server |
|---|---|---|
| srsRAN gNB | Section 3.1 | Server 1 |
| srsUE | Section 3.2 | Server 1 |
| E2 Simulator | Section 3.3 | Server 1 |
| OSC Near-RT RIC | Section 5.2 | Server 1 |
| Open5GS | Section 4.4 | Server 1 |

gNB and E2 Simulator connect to `e2term-sctp` pod via SCTP on port 32222. gNB-UE connection uses ZMQ.

### 6.2. Disaggregated Deployments

Each O-RAN component on a separate server. IP addresses:
- Open5GS Server: `192.0.13.3`
- srsRAN gNB Server: `192.0.13.4`
- FlexRIC Server: `192.0.13.7`

#### 6.2.1. Bare Metal Servers, ZMQ or USRP Connection

| Software | Installation Guide | Server |
|---|---|---|
| srsRAN gNB | Section 3.1 | Server 1 |
| srsUE | Section 3.2 | Workstation 1 |
| FlexRIC | Section 5.1.1 or 5.1.2 | Server 3 |
| Open5GS | Section 4.1 or 4.3 | Server 2 |

**Open5GS:** Replace `127.0.0.5` with `192.0.13.3` in `amf.yaml: ngap: addr` and `upf.yaml: gtpu: addr`.

**FlexRIC:** Change IP to `192.0.13.7` in `flexric.conf`.

**gNB:**

```yaml
amf:
    addr: 192.0.13.3
    bind_addr: 192.0.13.4

e2:
    enable_du_e2: true
    addr: 192.0.13.7
    bind_addr: 192.0.13.4
    e2sm_kpm_enabled: true
```

##### 6.2.1.1. ZMQ Connection

**gNB on Server 1** (TX: `192.0.13.4:2000`, RX from: `192.0.13.1:2001`):

```yaml
ru_sdr:
    device_driver: zmq
    device_args: tx_port=tcp://192.0.13.4:2000,rx_port=tcp://192.0.13.1:2001,base_srate=11.52e6
    srate: 11.52
    tx_gain: 75
    rx_gain: 35
```

**UE on Workstation 1:**

```ini
device_name = zmq
device_args = tx_port=tcp://192.0.13.1:2001,rx_port=tcp://192.0.13.4:2000,base_srate=11.52e6
```

##### 6.2.1.2. USRP Connection

Same configuration as [Section 6.1.2.2](#6122-usrp-connection). 50 dB attenuation between TX and RX ports.

#### 6.2.2. Multiple UEs via Channel Emulator

| Software | Installation Guide | Server |
|---|---|---|
| srsRAN gNB | Section 3.1 | Server 1 |
| srsUE1 | Section 3.2 | Workstation 1 |
| srsUE2 | Section 3.2 | Workstation 2 |
| srsUE3 | Section 3.2 | Workstation 3 |
| FlexRIC | Section 5.1.1 or 5.1.2 | Server 3 |
| Open5GS | Section 4.1 or 4.3 | Server 2 |

Uses Ettus B210 USRPs and Propsim F32 channel emulator. Each channel supports up to 40 MHz bandwidth with 43 dB total attenuation.

**UE1 config example:**

```ini
[rf]
freq_offset = 0
tx_gain = 75
rx_gain = 35
srate = 11.52e6
nof_antennas = 1
device_name = uhd
device_args = clock=external
time_adv_nsamples = 398

[usim]
mode = soft
algo = milenage
opc = 63BFA50EE6523365FF14C1F45F88737D
k = 00112233445566778899aabbccddeeff
imsi = 001010123456780
imei = 353490069873319
```

#### 6.2.3. Deployment with Containerized Open5GS

| Software | Installation Guide | Server |
|---|---|---|
| srsRAN gNB | Section 3.1 | Server 1 |
| srsUE | Section 3.2 | Workstation 1 |
| FlexRIC | Section 5.1.1 or 5.1.2 | Server 3 |
| Open5GS | Section 4.4 | Server 2 |

Dockerized Open5GS uses IP `10.53.1.2`.

**gNB config:**

```yaml
amf:
    addr: 10.53.1.2
    bind_addr: 192.0.13.4
```

**Add route on gNB server:**

```bash
sudo ip route add 10.53.1.0/24 via 192.0.13.3
```

---

## 7. Automation Tool

The automation tool, **O-RAN-Testbed-Automation**, is based on the deployment scenario in [Section 6.1.4](#614-kubernetes-osc-near-rt-ric-containerized-open5gs-e2-simulator-zmq) and installs Open5GS from source. Repository: [O-RAN-Testbed-Automation](https://github.com/usnistgov/O-RAN-Testbed-Automation) [14].

| Software | Installation Guide |
|---|---|
| srsRAN gNB | Section 3.1 |
| srsUE | Section 3.2 |
| E2 Simulator | Section 3.3 |
| OSC Near-RT RIC | Section 5.2 |
| Open5GS | Section 4.3 |

**Script structure:**
- `full_install.sh` — installs dependencies, clones repository, builds source, deploys application
- `generate_configurations.sh` — modifies default config files (.yaml or .conf) for IP addresses, ports, etc.
- `run.sh` — starts the application
- `stop.sh` — halts the application
- `is_running.sh` — outputs running status

The automation provides ZMQ connection between gNB and UE. USRP can be enabled by modifying configuration files in the `configs` directory.

---

## 8. Test Setup

### 8.1. Testbed

Deployment scenario from Section 6.2.1 (disaggregated, USRP). Ettus B210 with 50 dB attenuation.

- gNB Server: `192.0.13.4`
- Open5GS Server: `192.0.13.3`
- FlexRIC Server: `192.0.13.7`

### 8.2. Scripts and Configurations

**gnb.yaml:**

```yaml
amf:
    addr: 192.0.13.3
    bind_addr: 192.0.13.4

ru_sdr:
    device_driver: uhd
    device_args: type=b200
    clock: external
    sync: external
    srate: 11.52
    tx_gain: 75
    rx_gain: 35

cell_cfg:
    dl_arfcn: 368500
    band: 3
    channel_bandwidth_MHz: 10
    common_scs: 15
    plmn: "00101"
    tac: 7
    pdcch:
        dedicated:
            ss2_type: common
            dci_format_0_1_and_1_1: false
        common:
            ss0_index: 0
            coreset0_index: 6
    prach:
        prach_config_index: 1

log:
    filename: /tmp/gnb.log
    all_level: info
    hex_max_size: 0

pcap:
    mac_enable: false
    mac_filename: /tmp/gnb_mac.pcap
    ngap_enable: false
    ngap_filename: /tmp/gnb_ngap.pcap
    e2ap_enable: true
    e2ap_filename: /tmp/gnb_e2ap.pcap

e2:
    enable_du_e2: true
    addr: 192.0.13.7
    bind_addr: 192.0.13.4
    e2sm_kpm_enabled: true
```

> When using dockerized Open5GS, change `amf: addr` to `10.53.1.2` and add route: `sudo ip route add 10.53.1.0/24 via 192.0.13.3`

**ue.conf:**

```ini
[rf]
freq_offset = 0
tx_gain = 80
rx_gain = 35
srate = 11.52e6
nof_antennas = 1
device_name = uhd
device_args = clock=external
time_adv_nsamples = 300

[rat.eutra]
dl_earfcn = 2850
nof_carriers = 0

[rat.nr]
bands = 3
nof_carriers = 1
max_nof_prb = 52
nof_prb = 52

[pcap]
enable = none
mac_filename = /tmp/ue_mac.pcap
mac_nr_filename = /tmp/ue_mac_nr.pcap
nas_filename = /tmp/ue_nas.pcap

[log]
all_level = info
phy_lib_level = none
all_hex_limit = 32
filename = /tmp/ue.log
file_max_size = -1

[usim]
mode = soft
algo = milenage
opc = 63BFA50EE6523365FF14C1F45F88737D
k = 00112233445566778899aabbccddeeff
imsi = 001010123456780
imei = 353490069873319

[rrc]
release = 15
ue_category = 4

[nas]
apn = srsapn
apn_protocol = ipv4

[gui]
enable = false
```

**Open5GS (Package Manager):**

In `/etc/open5gs/amf.yaml`:

```yaml
ngap:
    - addr: 192.0.13.3
guami:
    - plmn_id:
        mcc: 001
        mnc: 01
tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 7
plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
```

In `/etc/open5gs/upf.yaml`:

```yaml
gtpu:
    - addr: 192.0.13.3
```

In `/etc/open5gs/nrf.yaml` (check/update if needed):

```yaml
nrf:
    serving:
        - plmn_id:
            mcc: 001
            mnc: 01
```

Restart:

```bash
sudo systemctl restart open5gs-nrfd   # if NRF changed
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-upfd
```

**Open5GS (from source):** Modify `amf`, `upf`, `nrf` sections in `open5gs/build/configs/sample.yaml`.

**FlexRIC:** In `/usr/local/etc/flexric/flexric.conf`:

```ini
[NEAR-RIC]
NEAR_RIC_IP = 192.0.13.7
```

### 8.3. Running Testbed

**1. Open5GS**

- Package Manager: NFs run automatically.
- From source: `cd open5gs && ./build/tests/app/5gc`
- Docker: `cd srsRAN_Project/docker/ && docker-compose up 5gc`

**2. FlexRIC (Server 3)**

```bash
./flexric/build/examples/ric/nearRT-RIC
```

Expected output:

```
[NEAR-RIC]: nearRT-RIC IP Address = 192.0.13.7, PORT = 36421
[NEAR-RIC]: Initializing
[NEAR-RIC]: Loading SM ID = 144 with def = PDCP_STATS_V0
[NEAR-RIC]: Loading SM ID = 147 with def = ORAN-E2SM-KPM
[NEAR-RIC]: Loading SM ID = 142 with def = MAC_STATS_V0
[NEAR-RIC]: Loading SM ID = 145 with def = SLICE_STATS_V0
[NEAR-RIC]: Loading SM ID = 146 with def = TC_STATS_V0
[NEAR-RIC]: Loading SM ID = 143 with def = RLC_STATS_V0
[NEAR-RIC]: Loading SM ID = 148 with def = GTP_STATS_V0
[iApp]: Initializing ...
[iApp]: nearRT-RIC IP Address = 192.0.13.7, PORT = 36422
```

**3. gNB (Server 2)**

```bash
sudo gnb -c gnb.yaml
```

Expected output:

```
--== srsRAN gNB (commit 5e6f50a20) ==--
Connecting to AMF on 192.0.13.3:38412
...
Connecting to NearRT-RIC on 192.0.13.7:36421
Cell pci=1, bw=10 MHz, dl_arfcn=368500 (n3), dl_freq=1842.5 MHz, dl_ssb_arfcn=368410, ul_freq=1747.5 MHz

==== gNodeB started ===
Type <t> to view trace
```

On successful connection, NearRT-RIC logs show:

```
Received message with id = 411, port = 30397
[E2AP] Received SETUP-REQUEST from PLMN 1. 1 Node ID 411 RAN type ngran_gNB
[NEAR-RIC]: Accepting RAN function ID 147 with def = ORAN-E2SM-KPM
```

AMF logs (`/var/log/open5gs/amf.log`):

```
[amf] INFO: gNB-N2 accepted[192.0.13.4] in master_sm module
[amf] INFO: [Added] Number of gNBs is now 1
```

**4. srsUE (Server 1)**

```bash
sudo srsue ue.conf
```

Expected output:

```
Random Access Transmission: prach_occasion=0, preamble_index=0, ra-rnti=0x39, tti=2574
Random Access Complete. c-rnti=0x4601, ta=0
RRC Connected
PDU Session Establishment successful. IP 10.45.0.33
RRC NR reconfiguration successful.
```

### 8.4. Tests

#### 8.4.1. Ping

IP addresses:
- 5G Core: `10.45.0.1`
- UE: `10.45.0.33` (changes on restart)

**Ping UE from 5G Core:**

```bash
ping 10.45.0.33 -c 10
```

**Ping 5G Core from UE:**

```bash
ping 10.45.0.1 -c 10
```

**Ping external site via tunnel:**

```bash
ping www.google.com -I tun_srsue -c 10
```

> **Note:** `-I tun_srsue` forces packets through the tunnel interface.

#### 8.4.2. Iperf3

**Uplink test:**

On Open5GS server:

```bash
iperf3 -s -i 1
```

On srsUE server:

```bash
iperf3 -c 10.45.0.1 -b 15M -i 1 -t 60
```

**Downlink test:**

On srsUE server:

```bash
iperf3 -s -i 1
```

On Open5GS server:

```bash
iperf3 -c 10.45.0.33 -b 15M -i 1 -t 60
```

Alternatively, add `-R` at the client side to reverse direction.

**Typical results:** ~14-15 Mbits/sec for both UL and DL with the test setup.

#### 8.4.3. xApp

Start E2SM-KPM xApp on FlexRIC server while testbed is running:

```bash
./flexric/build/examples/xApp/c/monitor/xapp_kpm_moni
```

Expected output:

```
[xApp]: E42 SETUP-RESPONSE received
[xApp]: xApp ID = 8
[xApp]: Successfully SUBSCRIBED to ran function = 147
Received RIC Indication:
---Metric: RSRP: Value: 32
Received RIC Indication:
---Metric: RSRP: Value: 34
...
```

---

## 9. Conclusion and Future Work

This documentation presents a foundational blueprint for setting up an O-RAN testbed from scratch. It covers:

- O-RAN architecture and software stacks
- Aggregated and disaggregated deployment scenarios
- Automation tool for streamlined deployment
- Configuration and operation examples

Future updates will include:
- OSC near-RT RIC provided by SRS (RAN Control, xApp modules)
- OSC non-RT RIC instructions
- OAI gNB and UE with X410 USRPs
- Extended deployment and test automation with diverse software stack choices

---

## References

1. O-RAN WG1 OAD (2024) *O-RAN Work Group 1 (Use Cases and Overall Architecture): O-RAN Architecture Description*. O-RAN Alliance, Standard.
2. Open Networking Foundation (2023) "Hardware Installation - Prerequisites". <https://docs.sd-ran.org/master/sdran-in-a-box/docs/HW_Installation_prereq.html>
3. srsRAN (2023) "Running srsRAN Project". <https://docs.srsran.com/projects/project/en/latest/user_manuals/source/running.html>
4. srsRAN (2023) "srsRAN Project - Installation Guide". <https://docs.srsran.com/projects/project/en/latest/user_manuals/source/installation.html>
5. srsRAN (2023) "srsRAN Project - srsRAN gNB with srsUE". <https://docs.srsran.com/projects/project/en/latest/tutorials/source/srsUE/source/index.html>
6. srsRAN (2023) "gnb_rf_b210_fdd_srsue.yml". <https://github.com/srsran/srsRAN_Project/blob/main/configs/gnb_rf_b210_fdd_srsUE.yml>
7. srsRAN (2023) "srsRAN 4G Features". <https://docs.srsran.com/projects/4g/en/latest/feature_list.html>
8. srsRAN (2023) "ue_rf.conf". <https://docs.srsran.com/projects/project/en/latest/_downloads/900a04eeabbe80c1bb9f3e571afaa804/ue_rf.conf>
9. Open5GS (2023) "Building Open5GS from Sources". <https://open5gs.org/open5gs/docs/guide/02-building-open5gs-from-sources/>
10. srsRAN (2023) "O-RAN NearRT-RIC and xApp". <https://docs.srsran.com/projects/project/en/latest/tutorials/source/flexric/source/index.html>
11. Open5GS (2023) "Quickstart". <https://open5gs.org/open5gs/docs/guide/01-quickstart/>
12. EURECOM (2024) "Flexric". <https://gitlab.eurecom.fr/mosaic5g/flexric>
13. srsRAN (2023) "Unknown RAN Function ID". <https://github.com/srsran/srsRAN_Project/discussions/368#discussioncomment-7909775>
14. Simeon Wuthier (2024) "O-RAN-Testbed-Automation". <https://github.com/usnistgov/O-RAN-Testbed-Automation>
