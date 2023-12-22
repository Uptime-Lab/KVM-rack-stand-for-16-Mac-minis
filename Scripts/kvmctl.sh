#!/bin/bash -e
# Simple control over a TESmart KVM using the LAN port or TX/RX connector.
# Much of this has been hardcoded due to limited functionality, a full description
# of the device and the protocol is in a separate .md file in the git repo.

# Default configuration

#ADDRESS="192.168.1.10"
#PORT="5000"

DEVICE="/dev/ttyAMA0"
SPEED="9600"

# Custom configuration
#ADDRESS=""
#DEVICE=""

# The number of ports available on the KVM
PORTS=16

# Prints the command usage and exits
function usage {
  progname=$(basename $0)
  echo "$progname -- Controls a TESmart KVM using TCP/IP or RS-232"
  echo "Usage:"
  printf "  %-24.23s: %-20s\n" "${progname} get" "Retrieves the active port number."
  printf "  %-24.23s: %-20s\n" "${progname} set <1-${PORTS}>" "Retrieves the active port number."
  printf "  %-24.23s: %-20s\n" "${progname} buzzer <0|1>" "Turns the buzzer off (0) or on (1)."
  printf "  %-24.23s: %-20s\n" "${progname} lcd <0|10|30>" "Disable or set the LCD timeout."
  printf "  %-24.23s: %-20s\n" "${progname} auto <0|1>" "Disable or enable auto input detection."
  exit 0;
}

# If communication fails, a value outside of range, "0xFF", so when it
# has been received by the caller there is an option to retry.
function sendCommand {
  # Preamble AABB03 + Token/Value + EE
  request="aabb03${1}ee"

  # Send to serial or via network depending on device
  if [ ! -z "$DEVICE" ]; then
    # Without raw buffering makes reads wait for newline characters which never come.
    response=$(
      stty -F $DEVICE speed $SPEED raw >/dev/null \
      && echo -n $request | xxd -r -p | socat - $DEVICE | xxd -p 2>/dev/null \
      || echo ff
    )
  else
    # Network communication requires a delay for stability.
    sleep 1

    # The -l6 is required to read response without waiting for a newline.
    # Beware gnu-netcat hangs waiting for something, openbsd-netcat works fine.
    response=$(
      echo $request | xxd -r -p | nc ${ADDRESS} ${PORT} | xxd -p -l6 2>/dev/null \
      || echo ff
    )
  fi

#  if [[ $response == ff ]]; then
#    echo "Unable to send request $request or read response." >&2
#    echo $response
#  elif [[ ! $response == aabb03* ]]; then
#    echo "Unrecognized response $response for request $request." >&2
#    echo ff
#  else
#    echo $response | cut -c 9-10
#  fi
}

# Mutes and unmutes the buzzer. We receive the output from the "API" but
# the output is ignored because it's unreliable. Hardware cares nothing
# about development best practices. It eats best practices for breakfast.
function setBuzzer {
  case $1 in
    0) out=$(sendCommand "0200")
       echo "Buzzer muted."
       ;;
    1) out=$(sendCommand "0201")
       echo "Buzzer unmuted."
       ;;
    *) echo "Buzzer only accepts 0 (off) or 1 (on)."
       exit 1
       ;;
  esac
}

# Sets the timeout value of the LCD. This does not appear to affect the
# LED lighting on the 8-port Tesmart switch but does appear on the 16-port
# documentation. This is treated similar to the buzzer settings.
function setTimeout {
  case $1 in
    0) out=$(sendCommand "0300")
       echo "LCD Timeout Disabled."
       ;;
    10) out=$(sendCommand "030A")
       echo "LCD Timeout set to 10 seconds."
       ;;
    30) out=$(sendCommand "031E")
       echo "LCD Timeout set to 30 seconds."
       ;;
    *) echo "Buzzer only accepts 0 (off) or 1 (on)."
       exit 1
       ;;
  esac
}

# Send the command 0x10 0x00 to read the current active port, retrying
# up to three times if the command fails. The function will either return
# the current port number or an error if communication failed.
function getPort {
  for ((i=0; i<3; i++)); do
    out=$(sendCommand "1000")
    if [[ $out != ff ]]; then break; fi
  done

  if [[ $out == ff ]]; then
    echo "Unable to retrieve current port."
    exit 1
  fi

  echo $((16#$out+1));
}

# Sets the current active port. This is the only function with an actual
# range check as the number must be between 1 and $PORTS and is the only
# function that requires a calculation for decimal to hex conversion.
function setPort {
  if [[ ${1} -lt 1 || ${1} -gt ${PORTS} ]]; then
    echo "Invalid port specified. Range is 1 to $PORTS."
    exit 1
  fi

  # Use the function to read the current port rather than relying on the
  # potentially unreliable output when the KVM UART first wakes up.
  # If the port is already active, don't change, just print the port.
#  oldport=$(getPort)
#  if [[ ${oldport} -eq ${1} ]]; then
#    echo "Port $oldport is already active."
#    exit 0
#  fi

  # Collect the output but don't rely on it. The command may still be
  # successful but won't print the new port number anyway.
  hexval=$(printf '%.2X\n' ${1})
  out=$(sendCommand "01${hexval}")

  # If a valid value was returned when the port was changed, it would have
  # returned the previous value. Attempt to give confirmation to the user
  # that the port was actually changed.
#  newport=$(getPort)
#  echo "Port changed from ${oldport} to ${newport}."
}

function setAuto {
  if [[ ${1} -lt 0 || ${1} -gt 1 ]]; then
    echo "Invalid port specified. Range is 1 to $PORTS."
    exit 1
  fi
  hexval=$(printf '%.2X\n' ${1})
  out=$(sendCommand "81${hexval}")
}

# Simple case statement to process the options
case $1 in
  get) echo "The current port is: $(getPort)";
    ;;
  set) setPort $2;
    ;;
  buzzer) setBuzzer $2;
    ;;
  lcd) setTimeout $2;
    ;;
  auto) setAuto $2;
    ;;
  *) usage
esac
