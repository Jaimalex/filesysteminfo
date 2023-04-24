#!/bin/bash

# Autor - Jaime Sendín
# Correo electrónico - alu0101500324@ull.edu.es
# Organización - Universidad de La Laguna
# Archivo - filesysteminfo.sh
# El script se centra en obtener información sobre los sistemas de archivos "montados" en el sistema. 

##### Estilos #####

# Estilo texto

TEXT_BOLD=$(tput bold)
TEXT_RESET=$(tput sgr0)
TEXT_UNLINE=$(tput sgr 0 1)

# Colores texto
  
TEXT_DEFBLACK=$(tput setaf 0)
TEXT_DEFRED=$(tput setaf 1)
TEXT_DEFGREEN=$(tput setaf 2)
TEXT_DEFYELLOW=$(tput setaf 3)
TEXT_DEFBLUE=$(tput setaf 4)
TEXT_BLUE=$(tput setaf 69)
TEXT_DEFMAGENTA=$(tput setaf 5)
TEXT_DEFCYAN=$(tput setaf 6)
TEXT_DEFWHITE=$(tput setaf 7)
TEXT_PINK=$(tput setaf 200)
TEXT_DEFCOLOR=$(tput setaf 9)

##### Constantes #####

titulo="Información del sistema de ${HOSTNAME}"
fecha=$(date +"%x %r%Z")
ultima_acualizacion="Actualizado el ${RIGHT_NOW} por ${USER}"

#### Variables ####

ordenar_columna=0
usuario=""
inv=""
usuario_device_files=""

# Control

device_files=0
param_usuario=0
op_usuario=0
no_encabezado=0
s_open=0
s_device=0

##### Funciones #####

Uso() {

cat << _FF_

  ${TEXT_BOLD}${TEXT_PINK}$(basename $0) - Script que informa del sistema de archivos${TEXT_RESET}
   
  ${TEXT_UNLINE}${TEXT_BLUE}Modo de ejecución:${TEXT_RESET} ${TEXT_BLUE}./filesysteminfo [-h|--help] [-u] [-sopen] [-sdevice] [-inv] [-devicefiles] [-noheader]${TEXT_RESET}

  ${TEXT_UNLINE}${TEXT_DEFCYAN}-----Parámetros-----${TEXT_RESET}
  ${TEXT_DEFCYAN}-h ${TEXT_RESET}; ${TEXT_DEFCYAN}--help${TEXT_RESET} - Muestra la ventana de ayuda.
  ${TEXT_DEFCYAN}-u${TEXT_RESET} - Filtrar por los archivos abiertos por el usuario real del proceso que mantiene abierto un archivo. Admitirá una lista de usuario.
  ${TEXT_DEFCYAN}-sopen${TEXT_RESET} - La ordenación se hará por el número de archivos abiertos, y solo se podrá usar con las opciones -devicefiles y/o -u.
  ${TEXT_DEFCYAN}-sdevice${TEXT_RESET} - La ordenación se realizará por el número total de dispositivos considerados para cada sistema de archivos.
  ${TEXT_DEFCYAN}-inv${TEXT_RESET} - La ordenación se realizará a la inversa.
  ${TEXT_DEFCYAN}-devicefiles${TEXT_RESET} - Considerar solo los dispositivos representados en el sistema operativo como archivos (device files).
  ${TEXT_DEFCYAN}-noheader${TEXT_RESET} - No considerar el encabezado para la representación.

_FF_
}  

DeteccionErrores() {
  
  if [ "$op_usuario" == "1" ] && [ "$usuario" == "" ];then
    echo "$(basename $0): Número de usuarios no válido."
    exit 1
  fi 

  if [ "$s_open" == "1" ] && [ "$s_device" == "1" ];then
    echo "$(basename $0): No pueden utilizarse simultáneamente las opciones -sopen y -sdevice."
    exit 1
  fi 

  if [ "$s_open" == "1" ] && [ "$op_usuario" == "0" ] && [ "$device_files" == "0" ];then
    echo "$(basename $0): La opción -sopen se debe emplear con -u o -devicefiles."
    exit 1
  fi 
}

SistemaArchivos() {

  if [ "$no_encabezado" == "0" ];then
    echo -n "${TEXT_BOLD}${TEXT_DEFBLUE}NºDispositivos Tipo Dispositivo Usado PuntoMontaje Ocupación Menor Mayor${TEXT_RESET}"
  fi
  if [ $device_files == "1" ] && [ "$no_encabezado" == "0" ];then
    echo -n "${TEXT_BOLD}${TEXT_DEFBLUE} NºDispositivosAbiertos${TEXT_RESET}"
  fi
  echo ""

  if [ "$ordenar_columna" == "0" ]; then
    SistemaArchivosMontados
    return 0
  else
    SistemaArchivosMontados | sort -k $ordenar_columna -n $inv
    return 0
  fi
}

SistemaArchivosMontados() {

  dispositivos_montados=$(mount | cut -d ' ' -f 5 | sort $inv | uniq)

  for dispositivo in $dispositivos_montados;do

    if [ "$device_files" == "1" ];then
      archivo_dispositivo_menor=$(stat -c="%T %t" $(df -aht $dispositivo --output=source | tail -n +2 | sort -k'2' -hr | head -n +1) 2>/dev/null)
      archivo_dispositivo_mayor=$(stat -c="%T %t" $(df -aht $dispositivo --output=source | tail -n +2 | sort -k'2' -hr | head -n +1) 2>/dev/null)
    fi
    if [ $? == "0" ];then 
      total_dispositivos=$(df -at $dispositivo | tail -n +2 | wc -l) 
      info_dispositivos=$(df -aht $dispositivo --output=source,used,target | tail -n +2 | sort -k'2' -hr | head -n +1) 
      suma_espacio_usado=$(df -at $dispositivo --output=used | tail -n +2 | awk '{ suma+=$1 } END { print suma }') 
      archivo_dispositivo_menor=$(stat -c"%T" $(df -aht $dispositivo --output=source | tail -n+2 | sort -k '2' -hr | head -n+1) 2>/dev/null || echo "*") 
      archivo_dispositivo_mayor=$(stat -c"%t" $(df -aht $dispositivo --output=source | tail -n+2 | sort -k '2' -hr | head -n+1) 2>/dev/null || echo "*") 
      imprimir="$total_dispositivos $dispositivo $info_dispositivos $suma_espacio_usado $archivo_dispositivo_menor $archivo_dispositivo_mayor"

      if [ "$device_files" == "1" ];then 
        archivo_dispositivo_menor=$(echo $archivo_dispositivo_menor | tr '[:upper:]' '[:lower:]') 
        archivo_dispositivo_mayor=$(echo $archivo_dispositivo_mayor | tr '[:upper:]' '[:lower:]')    
        archivo_dispositivo_menor=$(echo "obase=10; ibase=16;$archivo_dispositivo_menor;" | bc) 
        archivo_dispositivo_mayor=$(echo "obase=10; ibase=16;$archivo_dispositivo_mayor;" | bc)
        if [ "$op_usuario" == "1" ];then
          usuario_device_files="-u $usuario" 
        fi
        dispositivos_abiertos=$(lsof $usuario_device_files | grep "$archivo_dispositivo_menor,$archivo_dispositivo_mayor"|wc -l)
        imprimir="$imprimir $dispositivos_abiertos"
      fi
      echo "$imprimir"
    fi
  done 
}

##### Programa principal #####

main() { 

  while [ "$1" != "" ];do
    case "$1" in
      -h | --help)
        Uso
        exit 0
        ;;
      -u)
        device_files=1
        op_usuario=1
        param_usuario=1
        ;;
      -sdevice)
        s_device=1
        ordenar_columna=1
        param_usuario=0
        ;;
      -sopen)
        s_open=1
        ordenar_columna=9
        param_usuario=0
        ;;
      -inv)
        inv="-r"
        param_usuario=0 
        ;;
      -devicefiles)
        device_files=1
        param_usuario=0 
        ;;
      -noheader)
      no_encabezado=1
      param_usuario=0
        ;;
      *)
        if [ "$param_usuario" == "1" ];then
          usuario="${usuario} ${1}"
          # usuario="$usuario,$1"
        else
cat << _FF_

          ${TEXT_RESET}${TEXT_DEFRED}${TEXT_BOLD}[-]OPCIÓN NO VÁLIDA${TEXT_RESET}
_FF_
          Uso
          exit 1
        fi
        ;;
    esac
    shift
  done
  DeteccionErrores
  SistemaArchivos | column -t
}

main $@ 2>/dev/null
