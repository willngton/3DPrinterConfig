#!/bin/bash
#

### APENAS EXECUTA O SCRIPT QUEM TEM PERMISSAO DE ADMIN (ROOT)
#

if [ "$(id -u)" != 0 ];
then
    echo -e "\nExecute o script com o usuario \"root\" ou utilizando \"sudo\".\n"

    exit 0
fi


### VERIFICA CONEXAO COM INTERNET
#

WWW="dns.opendns.org"

if ! ping -c1 -q "$WWW" &>/dev/null;
then
    echo -e "\nRaspberry Pi sem conectividade com internet. Verifique:"
    echo -e "\n\t=> Cabo de rede ou..."
    echo -e "\n\t=> Dados de acesso para rede wireless (arquivo /etc/wpa_supplicant/wpa_supplicant.conf) ou..."
    echo -e "\n\t=> Servidores DNS (arquivo /etc/resolv.conf).\n"

    exit 0
fi


### SUBSTITUI REPOSITORIO DO S.O. (PARA CONTORNAR LENTIDAO NOS REPOSITORIOS DO BRASIL)
#

if [ "$(grep "raspberrypi.org" "/etc/apt/sources.list")" ];
then
    echo -e "\nEfetuando backup de /etc/apt/sources.list ..."
    
    cp /etc/apt/sources.list{,.ORIGINAL} 2>/dev/null

    echo -e "\nSubstituindo repositorios ..."

    sed -i 's/^deb/#deb/' /etc/apt/sources.list.ORIGINAL

    sed -i 's/raspberrypi.org/freemirror.org/g' /etc/apt/sources.list
fi


### ATUALIZA LISTA DE PACOTES DO REPOSITORIO E APLICA UPDATES NO S.O.
#

for ACAO in clean update upgrade dist-upgrade autoremove
do
    echo -e "\nAtualizando o sistema. Aguarde ..."

    apt $ACAO -qq -y
done 


### ADICIONA PARAMETROS DE CONFIGURACAO DO DISPLAY NO ARQUIVO DE BOOT
#

if [ ! "$(grep "MKS\ TS35" "/boot/config.txt")" ];
then
    echo -e "\nEfetuando backup de /boot/config.txt ..."
    
    cp /boot/config.txt{,.ORIGINAL} 2>/dev/null

    echo -e "\nConfigurando arquivo /boot/config.txt ..."

    sed -i 's/#hdmi_force_hotplug=\(.\)*/hdmi_force_hotplug=1/' /boot/config.txt

    sed -i 's/#hdmi_group=\(.\)*/hdmi_group=2/' /boot/config.txt

    sed -i 's/#hdmi_mode=\(.\)*/hdmi_mode=87/' /boot/config.txt

    sed -i 's/#dtparam=spi=\(.\)*/dtparam=spi=on/' /boot/config.txt

    echo -e "\n#### MKS TS35" | tee -a /boot/config.txt >/dev/null

    echo -e "\ndtoverlay=tinylcd35,rotate=270,speed=48000000,touch,touchgpio=23" | tee -a /boot/config.txt >/dev/null

    echo -e "\nhdmi_cvt=hdmi_cvt=400 300 60 1 0 0 0" | tee -a /boot/config.txt >/dev/null

    echo -e "\ndisplay_rotate=0\n" | tee -a /boot/config.txt >/dev/null
fi


### INSTALA GIT CLIENT, BAIXA FONTE, COMPILA E INSTALA O BINARIO FBCP
#

if [ ! $(which fbcp) ];
then
    echo -e "\nInstalando Git Client ..."

    apt install cmake git -qq -y

    cd /home/pi/

    echo -e "\nBaixando sources do pacote fbcp ..."

    git clone https://github.com/tasanakorn/rpi-fbcp

    mkdir ./rpi-fbcp/build

    cd rpi-fbcp/build/

    echo -e "\nCompilando fbcp ..."

    cmake ..

    make

    echo -e "\nInstalando fbcp ..."

    install fbcp /usr/local/bin/fbcp
fi


### CONFIGURA INICIALIZACAO DO FBCP E XORG (DISPLAY E TOUCH)
#
if [ ! "$(grep "fbcp" "/etc/rc.local")" ];
then
    echo -e "\nEfetuando backup de /etc/rc.local ..."
    
    cp /etc/rc.local{,.ORIGINAL} 2>/dev/null

    echo -e "\nHabilitando inicializacao do comando fbcp durante o boot do sistema ..."

    sed -i 's/^exit\ 0$/fbcp\ \&\n\nexit\ 0/' /etc/rc.local
fi


if [ ! -f "/usr/share/X11/xorg.conf.d/99-fbturbo.conf" ];
then
    echo -e "\nConfigurando Xorg - arquivo /usr/share/X11/xorg.conf.d/99-fbturbo.conf ..."

cat <<EOF >/usr/share/X11/xorg.conf.d/99-fbturbo.conf
# This is a minimal sample config file, which can be copied to
# /etc/X11/xorg.conf in order to make the Xorg server pick up
# and load xf86-video-fbturbo driver installed in the system.
#
# When troubleshooting, check /var/log/Xorg.0.log for the debugging
# output and error messages.
# Run "man fbturbo" to get additional information about the extra
# configuration options for tuning the driver.

Section "Device"
    Identifier "Allwinner A10/A13/A20 FBDEV"
    Driver "fbturbo"
    Option "fbdev" "/dev/fb1"

    Option "SwapbuffersWait" "true"
EndSection
EOF
fi

if [ ! -f "/etc/X11/xorg.conf.d/99-calibration.conf" ];
then
    echo -e "\nConfigurando Xorg - arquivo /etc/X11/xorg.conf.d/99-calibration.conf ..."

cat <<EOF >/etc/X11/xorg.conf.d/99-calibration.conf
Section "InputClass"
    Identifier "Calibration"
    MatchProduct "ADS7846 Touchscreen"
    Option "Calibration" "3936 227 268 3880"
    Option "SwapAxes" "1"
    Option "EmulateThirdButton" "1"
    Option "EmulateThirdButtonTimeout" "1000"
    Option "EmulateThirdButtonMoveThreshold" "300"
EndSection
EOF
fi


### ATUALIZA MODULO TINYLCD35
#
# ================ ATENCAO! ATENCAO! ATENCAO! ================
#
#    CASO ATUALIZE O KERNEL E O DISPLAY PARE DE FUNCIONAR, REMOVA O
#
# ARQUIVO "/boot/overlays/tinylcd35.dtbo.NEW" E EXECUTE O SCRIPT NOVAMENTE
#

if [ ! -f "/boot/overlays/tinylcd35.dtbo.NEW" ];
then
    echo -e "\nAtualizando modulo de kernel tinylcd35.dtbo ..."

cat <<EOF >/tmp/tinylcd35-dtbo
0A3+7QAAEtYAAAA4AAAQ+AAAACgAAAARAAAAEAAAAAAAAAHeAAAQwAAAAAAAAAAAAAAAAAAAAAAA
AAABAAAAAAAAAAMAAAANAAAAAGJyY20sYmNtMjgzNQAAAAAAAAABZnJhZ21lbnRAMAAAAAAAAwAA
AAQAAAAL/////wAAAAFfX292ZXJsYXlfXwAAAAADAAAABQAAABJva2F5AAAAAAAAAAIAAAACAAAA
AWZyYWdtZW50QDEAAAAAAAMAAAAEAAAAC/////8AAAABX19vdmVybGF5X18AAAAAAwAAAAkAAAAS
ZGlzYWJsZWQAAAAAAAAAAgAAAAIAAAABZnJhZ21lbnRAMgAAAAAAAwAAAAQAAAAL/////wAAAAFf
X292ZXJsYXlfXwAAAAADAAAACQAAABJkaXNhYmxlZAAAAAAAAAACAAAAAgAAAAFmcmFnbWVudEAz
AAAAAAADAAAABAAAAAv/////AAAAAV9fb3ZlcmxheV9fAAAAAAF0aW55bGNkMzVfcGlucwAAAAAA
AwAAAAwAAAAZAAAAGQAAABgAAAASAAAAAwAAAAQAAAAjAAAAAQAAAAMAAAAEAAAAMQAAAAEAAAAC
AAAAAXRpbnlsY2QzNV90c19waW5zAAAAAAAAAwAAAAQAAAAZAAAABQAAAAMAAAAEAAAAIwAAAAAA
AAADAAAABAAAADEAAAACAAAAAgAAAAFrZXlwYWRfcGlucwAAAAADAAAAFAAAABkAAAAEAAAAEQAA
ABYAAAAXAAAAGwAAAAMAAAAEAAAAIwAAAAAAAAADAAAABAAAADkAAAABAAAAAwAAAAQAAAAxAAAA
AwAAAAIAAAACAAAAAgAAAAFmcmFnbWVudEA0AAAAAAADAAAABAAAAAv/////AAAAAV9fb3Zlcmxh
eV9fAAAAAAMAAAAEAAAAQwAAAAEAAAADAAAABAAAAFIAAAAAAAAAAXRpbnlsY2QzNUAwAAAAAAMA
AAAPAAAAAG5lb3NlYyx0aW55bGNkAAAAAAADAAAABAAAAF4AAAAAAAAAAwAAAAgAAABiZGVmYXVs
dAAAAAADAAAACAAAAHAAAAABAAAAAgAAAAMAAAAEAAAAegLcbAAAAAADAAAABAAAAIwAAAEOAAAA
AwAAAAQAAACTAAAAFAAAAAMAAAAAAAAAlwAAAAMAAAAEAAAAmwAAAAgAAAADAAAADAAAAKT/////
AAAAGQAAAAEAAAADAAAADAAAALD/////AAAAGAAAAAAAAAADAAAADAAAALn/////AAAAEgAAAAEA
AAADAAAABAAAAMMAAAAAAAAAAwAAAPQAAADJAQAAsAAAAIABAADAAAAACgAAAAoBAADBAAAAAQAA
AAEBAADCAAAAMwEAAMUAAAAAAAAAQgAAAIABAACxAAAA0AAAABEBAAC0AAAAAgEAALYAAAAAAAAA
IgAAADsBAAC3AAAABwEAADYAAABYAQAA8AAAADYAAAClAAAA0wEAAOUAAACAAQAA5QAAAAEBAACz
AAAAAAEAAOUAAAAAAQAA8AAAADYAAAClAAAAUwEAAOAAAAAAAAAANQAAADMAAAAAAAAAAAAAAAAA
AAAAAAAANQAAADMAAAAAAAAAAAAAAAABAAA6AAAAVQEAABECAAABAQAAKQAAAAMAAAAEAAAAMQAA
AAQAAAACAAAAAXRpbnlsY2QzNV90c0AxAAAAAAADAAAACwAAAAB0aSxhZHM3ODQ2AAAAAAADAAAA
BAAAAF4AAAABAAAAAwAAAAkAAAASZGlzYWJsZWQAAAAAAAAAAwAAAAQAAAB6AB6EgAAAAAMAAAAI
AAAAzgAAAAUAAAACAAAAAwAAAAQAAADZ/////wAAAAMAAAAMAAAA6v////8AAAAFAAAAAAAAAAMA
AAACAAAA9wBkAAAAAAADAAAAAgAAAQcA/wAAAAAAAwAAAAQAAAAxAAAABQAAAAIAAAACAAAAAgAA
AAFmcmFnbWVudEA1AAAAAAADAAAABAAAAAv/////AAAAAV9fZG9ybWFudF9fAAAAAAMAAAAEAAAA
QwAAAAEAAAADAAAABAAAAFIAAAAAAAAAAwAAAAUAAAASb2theQAAAAAAAAABcGNmODU2M0A1MQAA
AAAAAwAAAAwAAAAAbnhwLHBjZjg1NjMAAAAAAwAAAAQAAABeAAAAUQAAAAMAAAAFAAAAEm9rYXkA
AAAAAAAAAwAAAAQAAAAxAAAABwAAAAIAAAACAAAAAgAAAAFmcmFnbWVudEA2AAAAAAADAAAABAAA
AAv/////AAAAAV9fZG9ybWFudF9fAAAAAAMAAAAEAAAAQwAAAAEAAAADAAAABAAAAFIAAAAAAAAA
AwAAAAUAAAASb2theQAAAAAAAAABZHMxMzA3QDY4AAAAAAAAAwAAAA4AAAAAZGFsbGFzLGRzMTMw
NwAAAAAAAAMAAAAEAAAAXgAAAGgAAAADAAAABQAAABJva2F5AAAAAAAAAAMAAAAEAAAAMQAAAAgA
AAACAAAAAgAAAAIAAAABZnJhZ21lbnRANwAAAAAAAwAAAAUAAAEXL3NvYwAAAAAAAAABX19vdmVy
bGF5X18AAAAAAWtleXBhZAAAAAAAAwAAAAoAAAAAZ3Bpby1rZXlzAAAAAAAAAwAAAAgAAABiZGVm
YXVsdAAAAAADAAAABAAAAHAAAAADAAAAAwAAAAkAAAASZGlzYWJsZWQAAAAAAAAAAwAAAAAAAAEj
AAAAAwAAAAQAAAAxAAAABgAAAAFidXR0b25AMTcAAAAAAAADAAAADAAAAS5HUElPIEtFWV9VUAAA
AAADAAAABAAAATQAAABnAAAAAwAAAAwAAACq/////wAAABEAAAAAAAAAAgAAAAFidXR0b25AMjIA
AAAAAAADAAAADgAAAS5HUElPIEtFWV9ET1dOAAAAAAAAAwAAAAQAAAE0AAAAbAAAAAMAAAAMAAAA
qv////8AAAAWAAAAAAAAAAIAAAABYnV0dG9uQDI3AAAAAAAAAwAAAA4AAAEuR1BJTyBLRVlfTEVG
VAAAAAAAAAMAAAAEAAABNAAAAGkAAAADAAAADAAAAKr/////AAAAGwAAAAAAAAACAAAAAWJ1dHRv
bkAyMwAAAAAAAAMAAAAPAAABLkdQSU8gS0VZX1JJR0hUAAAAAAADAAAABAAAATQAAABqAAAAAwAA
AAwAAACq/////wAAABcAAAAAAAAAAgAAAAFidXR0b25ANAAAAAAAAAADAAAADwAAAS5HUElPIEtF
WV9FTlRFUgAAAAAAAwAAAAQAAAE0AAAAHAAAAAMAAAAMAAAAqv////8AAAAEAAAAAAAAAAIAAAAC
AAAAAgAAAAIAAAABX19vdmVycmlkZXNfXwAAAAAAAAMAAAAYAAABPwAAAARzcGktbWF4LWZyZXF1
ZW5jeTowAAAAAAMAAAANAAAAjAAAAARyb3RhdGU6MAAAAAAAAAADAAAACgAAAJMAAAAEZnBzOjAA
AAAAAAADAAAADAAAAMMAAAAEZGVidWc6MAAAAAADAAAACwAAAUUAAAAFc3RhdHVzAAAAAAADAAAA
NAAAAUsAAAACYnJjbSxwaW5zOjAAAAAABWludGVycnVwdHM6MAAAAAAFcGVuZG93bi1ncGlvOjQA
AAAAAwAAABYAAAFVAAAABXRpLHgtcGxhdGUtb2htczswAAAAAAAAAwAAAAcAAAFbAAAAAD01AAAA
AAADAAAABwAAAWMAAAAAPTYAAAAAAAMAAAALAAABagAAAAZzdGF0dXMAAAAAAAIAAAABX19zeW1i
b2xzX18AAAAAAwAAACcAAAFxL2ZyYWdtZW50QDMvX19vdmVybGF5X18vdGlueWxjZDM1X3BpbnMA
AAAAAAMAAAAqAAABgC9mcmFnbWVudEAzL19fb3ZlcmxheV9fL3RpbnlsY2QzNV90c19waW5zAAAA
AAAAAwAAACQAAAGSL2ZyYWdtZW50QDMvX19vdmVybGF5X18va2V5cGFkX3BpbnMAAAAAAwAAACQA
AAGeL2ZyYWdtZW50QDQvX19vdmVybGF5X18vdGlueWxjZDM1QDAAAAAAAwAAACcAAAGoL2ZyYWdt
ZW50QDQvX19vdmVybGF5X18vdGlueWxjZDM1X3RzQDEAAAAAAAMAAAAjAAABtS9mcmFnbWVudEA1
L19fZG9ybWFudF9fL3BjZjg1NjNANTEAAAAAAAMAAAAiAAABvS9mcmFnbWVudEA2L19fZG9ybWFu
dF9fL2RzMTMwN0A2OAAAAAAAAAMAAAAfAAABai9mcmFnbWVudEA3L19fb3ZlcmxheV9fL2tleXBh
ZAAAAAAAAgAAAAFfX2ZpeHVwc19fAAAAAAADAAAAKgAAAcQvZnJhZ21lbnRAMDp0YXJnZXQ6MAAv
ZnJhZ21lbnRANDp0YXJnZXQ6MAAAAAAAAAMAAAAVAAAByS9mcmFnbWVudEAxOnRhcmdldDowAAAA
AAAAAAMAAAAVAAAB0S9mcmFnbWVudEAyOnRhcmdldDowAAAAAAAAAAMAAAIKAAAA8i9mcmFnbWVu
dEAzOnRhcmdldDowAC9mcmFnbWVudEA0L19fb3ZlcmxheV9fL3RpbnlsY2QzNUAwOnJlc2V0LWdw
aW9zOjAAL2ZyYWdtZW50QDQvX19vdmVybGF5X18vdGlueWxjZDM1QDA6ZGMtZ3Bpb3M6MAAvZnJh
Z21lbnRANC9fX292ZXJsYXlfXy90aW55bGNkMzVAMDpsZWQtZ3Bpb3M6MAAvZnJhZ21lbnRANC9f
X292ZXJsYXlfXy90aW55bGNkMzVfdHNAMTppbnRlcnJ1cHQtcGFyZW50OjAAL2ZyYWdtZW50QDQv
X19vdmVybGF5X18vdGlueWxjZDM1X3RzQDE6cGVuZG93bi1ncGlvOjAAL2ZyYWdtZW50QDcvX19v
dmVybGF5X18va2V5cGFkL2J1dHRvbkAxNzpncGlvczowAC9mcmFnbWVudEA3L19fb3ZlcmxheV9f
L2tleXBhZC9idXR0b25AMjI6Z3Bpb3M6MAAvZnJhZ21lbnRANy9fX292ZXJsYXlfXy9rZXlwYWQv
YnV0dG9uQDI3OmdwaW9zOjAAL2ZyYWdtZW50QDcvX19vdmVybGF5X18va2V5cGFkL2J1dHRvbkAy
MzpncGlvczowAC9mcmFnbWVudEA3L19fb3ZlcmxheV9fL2tleXBhZC9idXR0b25ANDpncGlvczow
AAAAAAAAAwAAACoAAAHZL2ZyYWdtZW50QDU6dGFyZ2V0OjAAL2ZyYWdtZW50QDY6dGFyZ2V0OjAA
AAAAAAACAAAAAV9fbG9jYWxfZml4dXBzX18AAAAAAAAAAWZyYWdtZW50QDQAAAAAAAFfX292ZXJs
YXlfXwAAAAABdGlueWxjZDM1QDAAAAAAAwAAAAgAAABwAAAAAAAAAAQAAAACAAAAAgAAAAIAAAAB
ZnJhZ21lbnRANwAAAAAAAV9fb3ZlcmxheV9fAAAAAAFrZXlwYWQAAAAAAAMAAAAEAAAAcAAAAAAA
AAACAAAAAgAAAAIAAAABX19vdmVycmlkZXNfXwAAAAAAAAMAAAAEAAABPwAAAAAAAAADAAAABAAA
AIwAAAAAAAAAAwAAAAQAAACTAAAAAAAAAAMAAAAEAAAAwwAAAAAAAAADAAAABAAAAUUAAAAAAAAA
AwAAAAwAAAFLAAAAAAAAABAAAAAhAAAAAwAAAAQAAAFVAAAAAAAAAAMAAAAEAAABagAAAAAAAAAC
AAAAAgAAAAIAAAAJY29tcGF0aWJsZQB0YXJnZXQAc3RhdHVzAGJyY20scGlucwBicmNtLGZ1bmN0
aW9uAHBoYW5kbGUAYnJjbSxwdWxsACNhZGRyZXNzLWNlbGxzACNzaXplLWNlbGxzAHJlZwBwaW5j
dHJsLW5hbWVzAHBpbmN0cmwtMABzcGktbWF4LWZyZXF1ZW5jeQByb3RhdGUAZnBzAGJncgBidXN3
aWR0aAByZXNldC1ncGlvcwBkYy1ncGlvcwBsZWQtZ3Bpb3MAZGVidWcAaW5pdABpbnRlcnJ1cHRz
AGludGVycnVwdC1wYXJlbnQAcGVuZG93bi1ncGlvAHRpLHgtcGxhdGUtb2htcwB0aSxwcmVzc3Vy
ZS1tYXgAdGFyZ2V0LXBhdGgAYXV0b3JlcGVhdABsYWJlbABsaW51eCxjb2RlAHNwZWVkAHRvdWNo
AHRvdWNoZ3BpbwB4b2htcwBydGMtcGNmAHJ0Yy1kcwBrZXlwYWQAdGlueWxjZDM1X3BpbnMAdGlu
eWxjZDM1X3RzX3BpbnMAa2V5cGFkX3BpbnMAdGlueWxjZDM1AHRpbnlsY2QzNV90cwBwY2Y4NTYz
AGRzMTMwNwBzcGkwAHNwaWRldjAAc3BpZGV2MQBpMmMxAA==
EOF

    echo "467c00fee69312e95dcd182d4f89317a  /tmp/tinylcd35-dtbo" >/tmp/tinylcd35-dtbo.md5sum

    if ! md5sum -c /tmp/tinylcd35-dtbo.md5sum &>/dev/null;
    then
        echo -e "\nModulo gerado incorretamente! Este script pode estar alterado!\n"

        echo -e "\nDesfazendo todas as modificacoes ...\n"

        exit 0
    fi

    base64 -d /tmp/tinylcd35-dtbo | tee /boot/overlays/tinylcd35.dtbo.NEW &>/dev/null

    mv /boot/overlays/tinylcd35.dtbo{,.ORIGINAL}

    cp /boot/overlays/tinylcd35.dtbo{.NEW,}
fi


### TA QUASE...
#
echo -e "\nInstalando pacote xserver-xorg-input-evdev ..."

apt install xserver-xorg-input-evdev -qq -y


### FIM
#

echo -e "\nInstalacao e configuracao finalizada! Reincie o sistema.\n"

