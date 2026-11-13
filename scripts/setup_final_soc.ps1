$base = "d:\1602-23-735-045_honourspoject\final_soc"
$src = "d:\1602-23-735-045_honourspoject\waveguard"
$crc_src = "d:\1602-23-735-045_honourspoject\rtl1\rtl\IPS\CRC"

# Create subdirectories
$subdirs = @(
    "doc",
    "firmware",
    "rtl\cpu",
    "rtl\interconnect",
    "rtl\memory",
    "rtl\ips\crc",
    "rtl\ips\dma",
    "rtl\ips\enhanced_timer",
    "rtl\ips\gpio",
    "rtl\ips\seven_segment",
    "rtl\ips\timer",
    "rtl\ips\uart",
    "rtl\soc",
    "tb\unit_tests",
    "tb\soc",
    "tb\vip\uvm",
    "scripts"
)

foreach ($d in $subdirs) {
    $targetPath = Join-Path $base $d
    if (-not (Test-Path $targetPath)) {
        New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
    }
}

# Copy documentation
Copy-Item (Join-Path $src "documentation\SoC_Architecture_and_Abstract.md") (Join-Path $base "doc\") -Force

# Copy firmware
Copy-Item (Join-Path $src "firmware\*") (Join-Path $base "firmware\") -Recurse -Force

# Copy RTL components
Copy-Item (Join-Path $src "rtl\interconnect\*") (Join-Path $base "rtl\interconnect\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\memory\*") (Join-Path $base "rtl\memory\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\soc\*") (Join-Path $base "rtl\soc\") -Recurse -Force

# Copy IPs
Copy-Item (Join-Path $src "rtl\ips\crc\*") (Join-Path $base "rtl\ips\crc\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\ips\dma\*") (Join-Path $base "rtl\ips\dma\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\ips\enhanced_timer\*") (Join-Path $base "rtl\ips\enhanced_timer\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\ips\gpio\*") (Join-Path $base "rtl\ips\gpio\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\ips\seven_segment\*") (Join-Path $base "rtl\ips\seven_segment\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\ips\timer\*") (Join-Path $base "rtl\ips\timer\") -Recurse -Force
Copy-Item (Join-Path $src "rtl\ips\uart\*") (Join-Path $base "rtl\ips\uart\") -Recurse -Force

# Copy Testbenches
Copy-Item (Join-Path $src "verification\unit_tests\*") (Join-Path $base "tb\unit_tests\") -Recurse -Force
Copy-Item (Join-Path $src "verification\tb\*") (Join-Path $base "tb\soc\") -Recurse -Force

# Copy UVM VIP from rtl1 (excluding sim artifacts like simv or fsdb)
$uvm_src = Join-Path $crc_src "verification"
if (Test-Path $uvm_src) {
    Copy-Item (Join-Path $uvm_src "agents") (Join-Path $base "tb\vip\uvm\") -Recurse -Force
    Copy-Item (Join-Path $uvm_src "env") (Join-Path $base "tb\vip\uvm\") -Recurse -Force
    Copy-Item (Join-Path $uvm_src "interfaces") (Join-Path $base "tb\vip\uvm\") -Recurse -Force
    Copy-Item (Join-Path $uvm_src "sequences") (Join-Path $base "tb\vip\uvm\") -Recurse -Force
    Copy-Item (Join-Path $uvm_src "tests") (Join-Path $base "tb\vip\uvm\") -Recurse -Force
    if (Test-Path (Join-Path $uvm_src "soc_verification_pkg.sv")) {
        Copy-Item (Join-Path $uvm_src "soc_verification_pkg.sv") (Join-Path $base "tb\vip\uvm\") -Force
    }
    if (Test-Path (Join-Path $uvm_src "soc_verification_top.sv")) {
        Copy-Item (Join-Path $uvm_src "soc_verification_top.sv") (Join-Path $base "tb\vip\uvm\") -Force
    }
}

# Copy scripts
Copy-Item (Join-Path $src "scripts\*") (Join-Path $base "scripts\") -Recurse -Force

Write-Output "Setup of final_soc completed successfully!"
