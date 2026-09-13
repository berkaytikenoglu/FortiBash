# 🛡️ BashWAF Suite: Multi-Platform Server Hardening & Security Auditor

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Multi-OS](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows%20(WSL)-brightgreen.svg)]()
[![Security: Enterprise Hardened](https://img.shields.io/badge/Security-Enterprise%20WAF%20%26%20Fail2ban-red.svg)]()

**BashWAF**, yeni kurulan veya üretim ortamındaki sunucuları tek bir komutla koruma altına alan, **Web Application Firewall (WAF)**, **Fail2ban (b2fail)** saldırı engelleme, **Linux Çekirdek (Sysctl) sıkılaştırması**, **Güvenlik Duvarı (UFW/Firewalld)** ve **Otomatik Güvenlik Yamaları** kuran kurumsal bir siber güvenlik otomasyon paketidir.

Aynı zamanda yerel ve uzak ağlardaki cihazları keşfeden, açık portları tarayan ve varsayılan Linux güvenlik zaafiyetlerini (şifresiz veritabanları, SSH zayıf konfigürasyonları, telnet, açık paylaşım portları) denetleyen bağımsız bir **Network Auditor** aracı içerir.

---

## 🚀 Hızlı Başlangıç (Tek Komutla Kurulum)

Sıfır bir Linux sunucuda (Ubuntu, Debian, RHEL, Rocky, AlmaLinux, Arch, Alpine) veya macOS/WSL ortamında doğrudan çalıştırmak için:

```bash
curl -sSL https://raw.githubusercontent.com/berkaytikenoglu/bashwaf/main/install.sh | sudo bash
```

Veya yerel depoyu klonlayarak çalıştırmak için:

```bash
git clone https://github.com/berkaytikenoglu/bashwaf.git
cd bashwaf
chmod +x bin/bashwaf main.sh install.sh
./main.sh
```

---

## 🏛️ Proje Mimarisi (Clean Architecture)

Proje, uluslararası kodlama standartlarına uygun olarak tamamen **İngilizce modüler mimari** ile yapılandırılmıştır:

```
bashwaf/
├── bin/
│   └── bashwaf                        # Bağımsız CLI çalıştırılabilir dosyası
├── config/
│   ├── bad_bots.conf                  # Zararlı tarayıcı ve bot filtreleme haritası
│   ├── security_headers.conf          # HTTP güvenlik başlıkları (CSP, HSTS, X-Frame)
│   ├── sysctl_hardening.conf          # Linux çekirdek bellek & ağ sıkılaştırma kuralları
│   └── waf_rules.conf                 # SQLi, XSS, Path Traversal WAF filtreleme kuralları
├── core/
│   ├── engine.sh                      # Ana etkileşimli kontrolcü ve OS yönlendirme motoru
│   ├── os_detector.sh                 # Çoklu platform OS algılama (Linux, macOS, Windows/WSL)
│   ├── package_manager.sh             # Paket yöneticisi sarmalayıcısı (apt, dnf, pacman, apk, brew)
│   └── ui.sh                          # ANSI terminal tasarımı, durum tabloları ve log motoru
├── modules/
│   ├── linux/
│   │   ├── core/                      # Linux Temel Güvenlik Motorları (Ana Programlar)
│   │   │   ├── auto_updates.sh        # Otomatik güvenlik yamaları (unattended-upgrades / dnf-automatic)
│   │   │   ├── fail2ban_setup.sh      # Fail2ban (b2fail) brute-force & bot koruma jail'leri
│   │   │   ├── firewall_setup.sh      # UFW / Firewalld dinamik kural & port yöneticisi
│   │   │   ├── sysctl_hardening.sh    # Kernel SYN flood, IP spoofing & ASLR bellek koruması
│   │   │   ├── user_hardening.sh      # Sudo kullanıcısı & SSH root/şifre kilitleme
│   │   │   └── waf_setup.sh           # Nginx + WAF & Anti-DDoS hız sınırlaması
│   │   └── utils/                     # Linux Yardımcı Araçlar (Yardımcı Programlar & Test)
│   │       ├── baseline_audit.sh      # Yerel CIS Linux güvenlik uyumluluk denetleyicisi
│   │       ├── diagnostic_tools.sh    # Sistem analiz araç paketi (htop, lsof, jq, curl, net-tools)
│   │       └── service_verifier.sh    # Canlı servis doğrulama ve test motoru ([PASS] / [FAIL])
│   ├── macos/
│   │   ├── core/                      # macOS Güvenlik Motorları
│   │   │   ├── firewall_setup.sh      # macOS socketfilterfw & Gizlilik (Stealth) modu
│   │   │   ├── ssh_hardening.sh       # macOS SSH sunucu sıkılaştırması
│   │   │   └── system_update.sh       # Apple softwareupdate & Homebrew güncellemeleri
│   │   └── utils/
│   │       └── diagnostic_tools.sh    # Homebrew güvenlik araçları (nmap, htop, jq)
│   └── windows/
│       ├── core/                      # Windows & WSL Güvenlik Motorları
│       │   ├── firewall_bridge.sh     # Windows Defender Firewall & WSL2 port proxy köprüsü
│       │   └── wsl_hardening.sh       # WSL2 Linux subsystem sıkılaştırma (/etc/wsl.conf)
│       └── utils/
│           └── package_installer.sh   # Winget & Chocolatey güvenlik araçları yükleyicisi
├── auditor/                           # Bağımsız Ağ ve Zafiyet Denetleyicisi
│   ├── auditor.sh                     # Ağ tarayıcı ana giriş betiği
│   ├── discovery.sh                   # Alt ağ keşfi, ARP analizi ve Hostname çözümleyici
│   ├── port_scanner.sh                # Paralel çoklu iş parçacıklı TCP port tarayıcısı
│   ├── reporter.sh                    # ANSI durum tablosu ve JSON rapor üreticisi
│   └── vuln_checker.sh                # Zafiyet denetleyici (SSH Posture, Redis, DB, Web .env)
├── install.sh                         # Uzak curl / kurulum giriş noktası
├── main.sh                            # Ana başlatıcı kısayolu
└── README.md                          # Detaylı dokümantasyon
```

---

## 🖥️ İnteraktif Kontrol Paneli & Menü Akışı

Çalıştırıldığında ortamı otomatik algılar veya dilediğiniz işletim sistemini seçmenize olanak tanır:

```text
 █▀▀█ █▀▀█ █▀▀█ ▀▀█▀▀ █▀▀ █▀▀ ▀▀█▀▀   █▀▀█ █▀▀▄ █▀▀▄   █▀▀█ █  █ █▀▀▄ ░▀░ ▀▀█▀▀
 █▄▄█ █▄▄▀ █  █   █   █▀▀ █      █     █▄▄█ █  █ █  █   █▄▄█ █  █ █  █ ▀█▀   █  
 █    ▀ ▀▀ ▀▀▀▀   ▀   ▀▀▀ ▀▀▀    ▀     ▀  ▀ ▀  ▀ ▀▀▀    ▀  ▀ ░▀▀▀ ▀▀▀  ▀▀▀   ▀  

 [🛡️ CORE SECURITY ENGINES]   [🧰 UTILITY & DIAGNOSTIC PACK]   [🧪 TEST RUNNER]
 ─────────────────────────────────────────────────────────────────────────────────

┌────────────────────────────────────────┬──────────────────────┬─────────────────┐
│ SECURITY MODULE / COMPONENT            │ INSTALL STATUS       │ SERVICE STATE   │
├────────────────────────────────────────┼──────────────────────┼─────────────────┤
│ Fail2ban (b2fail) Engine               │ ✔ INSTALLED          │ ACTIVE          │
│ Nginx Web App Firewall (WAF)           │ ✔ INSTALLED          │ ACTIVE (Filtered│
│ Host Firewall (UFW/Firewalld)          │ ✔ CONFIGURED         │ ACTIVE          │
│ Kernel Sysctl Hardening                │ ✔ CONFIGURED         │ HARDENED        │
│ SSH Root Password Lockout              │ ✔ CONFIGURED         │ HARDENED        │
│ Automated Security Updates             │ ✔ CONFIGURED         │ ACTIVE          │
└────────────────────────────────────────┴──────────────────────┴─────────────────┘

┌── 🛡️ [CORE SECURITY ENGINES] ─────────────────────────────────────────────┐
│  [1] ⚡ Full System Hardening (Install All Engines + WAF)                 │
│  [2] Fail2ban (b2fail) Intrusion Prevention & Bot Jails                   │
│  [3] Nginx Web Application Firewall (SQLi, XSS, Bot Blocker, Rate-Limit)  │
│  [4] Host Firewall Configuration (UFW / Firewalld)                         │
│  [5] Linux Kernel (Sysctl) Network & Memory ASLR Hardening                │
│  [6] Sudo User Creation & SSH Root Password Lockout                       │
│  [7] Automated Security Updates & Unattended Upgrades                     │
└───────────────────────────────────────────────────────────────────────────┘
┌── 🧰 [UTILITY & DIAGNOSTIC PACK] ─────────────────────────────────────────┐
│  [8] 📡 Network Auditor & Vulnerability Scanner (Host & Port Inspector)   │
│  [9] Install Diagnostic Utilities (htop, lsof, jq, curl, iftop, net-tools)│
│  [10]Local CIS Baseline & Configuration Security Audit                    │
└───────────────────────────────────────────────────────────────────────────┘
┌── 🧪 [LIVE TEST & VERIFICATION RUNNER] ───────────────────────────────────┐
│  [11]Run Live Verification & Status Test on Installed Engines             │
└───────────────────────────────────────────────────────────────────────────┘
  [O] Switch OS Mode    [R] Refresh Matrix    [0] Exit
```

---

## 🧪 Canlı Servis Doğrulama ve Test Motoru (`[11] Run Live Verification`)

Kurulu olan motorların (WAF kuralları, Fail2ban daemon, Güvenlik duvarı kuralları, Çekirdek parametreleri) gerçekten çalıştığını ve sözdizim hatası barındırmadığını canlı olarak test eder:

```text
┌────────────────────────────────────────┬──────────────────────┬─────────────────┐
│ VERIFICATION TEST                      │ INSTALL STATUS       │ TEST RESULT     │
├────────────────────────────────────────┼──────────────────────┼─────────────────┤
│ Nginx WAF Rule Integrity               │ ✔ INSTALLED          │ PASS (Valid)    │
│ Fail2ban (b2fail) Engine               │ ✔ INSTALLED          │ PASS (3 Jails)  │
│ UFW Host Firewall                      │ ✔ INSTALLED          │ PASS (Active)   │
│ Linux Kernel Sysctl Hardening          │ ✔ CONFIGURED         │ PASS (Hardened) │
│ SSH Root Password Lockout              │ ✔ CONFIGURED         │ PASS (Locked)   │
│ Automated Security Updates             │ ✔ CONFIGURED         │ PASS (Auto-Patch│
└────────────────────────────────────────┴──────────────────────┴─────────────────┘
```

---

## 📡 Network Auditor (Ağ Tarayıcı & Zafiyet Denetleyicisi)

Ağdaki cihazları keşfetmek, cihaz adlarını (`Hostname`) görmek ve açık portlardaki zafiyetleri denetlemek için:

```bash
./auditor/auditor.sh
```

### Canlı Keşif ve Zafiyet Raporu:
```text
┌──────┬──────────────────┬─────────────────────────────┬──────────────────────────┐
│ NO   │ DEVICE IP        │ HOSTNAME / RESOLVED NAME    │ DEVICE ROLE / STATUS     │
├──────┼──────────────────┼─────────────────────────────┼──────────────────────────┤
│ [1 ] │ 192.168.1.1      │ Gateway / Router            │ Modem / Gateway Router   │
│ [2 ] │ 192.168.1.121    │ Ubuntu-Server.local         │ Active Network Node      │
│ [3 ] │ 192.168.1.156    │ Localhost (MacBook)         │ This Machine (Host)      │
└──────┴──────────────────┴─────────────────────────────┴──────────────────────────┘

┌──────────────────┬──────────────┬────────────┬─────────────────────────────┬────────────────────────────────────────────────────────┐
│ TARGET IP        │ PORT/SERVICE │ SEVERITY   │ FINDING / ISSUE             │ DETAILS / REMEDIATION                                  │
├──────────────────┼──────────────┼────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤
│ 192.168.1.121    │ 6379/Redis   │  CRITICAL  │ Unauthenticated Redis DB    │ Redis responds to commands without password!           │
│ 192.168.1.121    │ 22/SSH       │    HIGH    │ SSH Password Auth Active    │ Server accepts password auth; enforce SSH key only.    │
│ 192.168.1.1      │ 80/HTTP      │    LOW     │ Missing HTTP Security Header│ Missing: X-Frame-Options Content-Security-Policy       │
└──────────────────┴──────────────┴────────────┴─────────────────────────────┴────────────────────────────────────────────────────────┘
```

---

## 📜 Lisans
Bu proje MIT lisansı ile lisanslanmıştır.
