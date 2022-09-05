<# 
.SYNOPSIS 
  Compares configuration between two Edges that should have similar configurations

.DESCRIPTION
  This will compare the configuration between two edges. Useful for ECMP where in general, you have the same configuration across
  Only specific known requirement configuration is being checked, e.g. only BGP and staticRoutes are checked no OSPF.
 
.NOTES 
  Kelvin Wong, 1.0, 24 AUG 2022: Base version
  
.REQUIREMENT
  - PowerNSX module is loaded
  - Logged on to NSX with at least read-only credentials
   
.PARAMETER EdgeName1
  Name of NSX Edge (base)

.PARAMETER EdgeName2
  Name of NSX Edge (to be compared with)
#>

Param
(
  [Parameter(Mandatory=$true)]
  [String]$EdgeName1,
  [Parameter(Mandatory=$true)]
  [String]$EdgeName2
)

$edge1 = Get-NsxEdge -name $EdgeName1
$edge2 = Get-NsxEdge -name $EdgeName2

$PropsItems = @(
"GeneralConfig:enableAesni"
"GeneralConfig:enableFips"
"GeneralConfig:vseLogLevel"
"GeneralConfig:appliances.appliancesize"
"GeneralSSH:clisettings.remoteAccess"
"GeneralSyslog:features.syslog.serverAddresses.ipAddress"
"GeneralHA:features.highAvailability.enabled"
"RoutingGlobal:features.routing.routingGlobalConfig.ecmp"
"RoutingGlobal:features.routing.routingGlobalConfig.logging.enable"
"RoutingGlobal:features.routing.routingGlobalConfig.logging.logLevel"
"RoutingBGP:features.routing.bgp.localAS"
"RoutingBGP:features.routing.bgp.gracefulRestart"
"RoutingBGP:features.routing.bgp.defaultOriginate"
)

ForEach ($PropItem in $PropsItems) {

$desc = $PropItem.split(":")[0]
$prop = $PropItem.split(":")[1]

$prop1 = '$edge1.' + $prop
$prop2 = '$edge2.' + $prop

$result1 = Invoke-Expression $prop1
$result2 = Invoke-Expression $prop2

$message = "{0} -> {1} -> 1:{2}|2:{3}" -f $desc,$prop,$result1,$result2
if ($result1 -ne $result2){
  Write-Host $message -ForegroundColor Red
}
else {
  Write-Host $message -ForegroundColor Green
}

}

$vnics1 = $edge1.vnics.vnic | Where-Object { $_.isconnected -eq $true}
$vnics2 = $edge2.vnics.vnic | Where-Object { $_.isconnected -eq $true}

if ($vnics2.count -gt $vnics1.count) {
  Write-Host "vnic -> $EdgeName2 has extra vnic configured" -ForegroundColor red
}

$vnicProps = @(
"vnic:mtu"
"vnic:type"
"vnic:portgroupId"
"vnic:enableProxyArp"
"vnic:enableSendRedirects"
)

foreach ( $vnic1 in $vnics1) {
  
  $vnic2 = $null
  $vnic2 = $vnics2 | Where-Object { $_.label -eq  $vnic1.label}
  if ($null -ne $vnic2) {
 
    ForEach ($vnicProp in $vnicProps) {

      $desc = $vnicProp.split(":")[0]
      $prop = $vnicProp.split(":")[1]
      
      $prop1 = '$vnic1.' + $prop
      $prop2 = '$vnic2.' + $prop

      $result1 = Invoke-Expression $prop1
      $result2 = Invoke-Expression $prop2

      $message = "{0} -> {1}.{2} -> 1:{3}|2:{4}" -f $desc,$vnic1.label,$prop,$result1,$result2
      if ($result1 -ne $result2){
        Write-Host $message -ForegroundColor Red
      }
      else {
        Write-Host $message -ForegroundColor Green
      } 
    }
  }
  else {
    Write-Host "vnic -> vnic, $($vnic1.label), not found in $EdgeName2" -ForegroundColor red
  }
  
}


$StaticRts1 = $edge1.features.routing.staticRouting.staticRoutes.route
$StaticRts2 = $edge2.features.routing.staticRouting.staticRoutes.route

if ($StaticRts2.count -gt $StaticRts1.count) {
  Write-Host "StaticRt -> $EdgeName2 has extra static routes configured" -ForegroundColor red
}

$staticRtProps = @(
"staticRt:nextHop"
"staticRt:adminDistance"
)

foreach ( $StaticRt1 in $StaticRts1) {
  
  $StaticRt2 = $null
  $StaticRt2 = $StaticRts2 | Where-Object { $_.network -eq  $StaticRt1.network}
  if ($null -ne $StaticRt2) {
 
    ForEach ($staticRtProp in $staticRtProps) {

      $desc = $staticRtProp.split(":")[0]
      $prop = $staticRtProp.split(":")[1]
      
      $prop1 = '$StaticRt1.' + $prop
      $prop2 = '$StaticRt2.' + $prop

      $result1 = Invoke-Expression $prop1
      $result2 = Invoke-Expression $prop2

      $message = "{0} -> {1}.{2} -> 1:{3}|2:{4}" -f $desc,$StaticRt1.network,$prop,$result1,$result2
      if ($result1 -ne $result2){
        Write-Host $message -ForegroundColor Red
      }
      else {
        Write-Host $message -ForegroundColor Green
      } 
    }
  }
  else {
    Write-Host "StaticRt -> Static route, $($StaticRt1.network), not found in $EdgeName2" -ForegroundColor red
  }
  
}


$RoutingBGPNeighbrs1 = $edge1.features.routing.bgp.bgpNeighbours.bgpNeighbour
$RoutingBGPNeighbrs2 = $edge2.features.routing.bgp.bgpNeighbours.bgpNeighbour

if ($RoutingBGPNeighbrs2.count -gt $RoutingBGPNeighbrs1.count) {
  Write-Host "RoutingBGPNeighbr -> $EdgeName2 has extra neighbors configured" -ForegroundColor red
}

$RoutingBGPNeighbrProps = @(
"RoutingBGPNeighbr:remoteAS"
"RoutingBGPNeighbr:weight"
"RoutingBGPNeighbr:holdDownTimer"
"RoutingBGPNeighbr:keepAliveTimer"
"RoutingBGPNeighbr:removePrivateAS"
)

foreach ( $RoutingBGPNeighbr1 in $RoutingBGPNeighbrs1) {
  
  $RoutingBGPNeighbr2 = $null
  $RoutingBGPNeighbr2 = $RoutingBGPNeighbrs2 | Where-Object { $_.ipaddress -eq  $RoutingBGPNeighbr1.ipaddress}
  if ($null -ne $RoutingBGPNeighbr2) {
 
    ForEach ($RoutingBGPNeighbrProp in $RoutingBGPNeighbrProps) {

      $desc = $RoutingBGPNeighbrProp.split(":")[0]
      $prop = $RoutingBGPNeighbrProp.split(":")[1]
      
      $prop1 = '$RoutingBGPNeighbr1.' + $prop
      $prop2 = '$RoutingBGPNeighbr2.' + $prop

      $result1 = Invoke-Expression $prop1
      $result2 = Invoke-Expression $prop2

      $message = "{0} -> {1}.{2} -> 1:{3}|2:{4}" -f $desc,$RoutingBGPNeighbr1.ipaddress,$prop,$result1,$result2
      if ($result1 -ne $result2){
        Write-Host $message -ForegroundColor Red
      }
      else {
        Write-Host $message -ForegroundColor Green
      } 
    }
  }
  else {
    Write-Host "RoutingBGPNeighbr -> Neighbour, $($RoutingBGPNeighbr1.ipaddress), not found in $EdgeName2" -ForegroundColor red
  }
  
}
