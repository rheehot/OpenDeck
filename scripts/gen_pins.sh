#!/bin/bash

PIN_FILE=$1

mkdir -p board/gen/"$(basename "$PIN_FILE" .yml)"

OUT_FILE_HEADER=board/gen/"$(basename "$PIN_FILE" .yml)"/Pins.h
OUT_FILE_SOURCE=board/gen/"$(basename "$PIN_FILE" .yml)"/Pins.cpp

declare -i digital_inputs
declare -i digital_inputs_indexed
declare -i digital_outputs
declare -i digital_outputs_indexed
declare -i analog_inputs
declare -i analog_inputs_indexed

digital_inputs=$(yq r "$PIN_FILE" buttons.pins --length)
digital_inputs_indexed=$(yq r "$PIN_FILE" buttons.indexing --length)
digital_in_type=$(yq r "$PIN_FILE" buttons.type)
digital_outputs=$(yq r "$PIN_FILE" leds.external.pins --length)
digital_outputs_indexed=$(yq r "$PIN_FILE" leds.external.indexing --length)
digital_out_type=$(yq r "$PIN_FILE" leds.external.type)
analog_inputs=$(yq r "$PIN_FILE" analog.pins --length)
analog_inputs_indexed=$(yq r "$PIN_FILE" analog.indexing --length)
analog_in_type=$(yq r "$PIN_FILE" analog.type)

{
    printf "%s\n\n" "#include \"core/src/general/IO.h\""
} > "$OUT_FILE_HEADER"

{
    printf "%s\n\n" "#include \"Pins.h\""
    printf "%s\n\n" "namespace {"
} > "$OUT_FILE_SOURCE"

if [[ $digital_inputs_indexed -ne 0 ]]
then
    digital_inputs=$digital_inputs_indexed

    printf "%s\n" "const uint8_t buttonIndexes[MAX_NUMBER_OF_BUTTONS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<digital_inputs; i++))
    do
        index=$(yq r "$PIN_FILE" buttons.indexing["$i"])
        printf "%s\n" "${index}," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
fi

if [[ $digital_in_type == native ]]
then
    printf "%s\n" "const core::io::mcuPin_t dInPins[MAX_NUMBER_OF_BUTTONS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<digital_inputs; i++))
    do
        port=$(yq r "$PIN_FILE" buttons.pins["$i"].port)
        index=$(yq r "$PIN_FILE" buttons.pins["$i"].index)

        {
            printf "%s\n" "#define DIN_PORT_${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define DIN_PIN_${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        printf "%s\n" "CORE_IO_MCU_PIN_DEF(DIN_PORT_${i}, DIN_PIN_${i})," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
elif [[ $digital_in_type == shiftRegister ]]
then
    port=$(yq r "$PIN_FILE" buttons.pins.data.port)
    index=$(yq r "$PIN_FILE" buttons.pins.data.index)

    {
        printf "%s\n" "#define SR_IN_DATA_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_IN_DATA_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" buttons.pins.clock.port)
    index=$(yq r "$PIN_FILE" buttons.pins.clock.index)

    {
        printf "%s\n" "#define SR_IN_CLK_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_IN_CLK_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" buttons.pins.latch.port)
    index=$(yq r "$PIN_FILE" buttons.pins.latch.index)

    {
        printf "%s\n" "#define SR_IN_LATCH_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_IN_LATCH_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
elif [[ $digital_in_type == matrix ]]
then
    if [[ $(yq r "$PIN_FILE" buttons.rows.type) == "shiftRegister" ]]
    then
        port=$(yq r "$PIN_FILE" buttons.rows.pins.data.port)
        index=$(yq r "$PIN_FILE" buttons.rows.pins.data.index)

        {
            printf "%s\n" "#define SR_IN_DATA_PORT CORE_IO_PORT(${port})"
            printf "%s\n" "#define SR_IN_DATA_PIN CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        port=$(yq r "$PIN_FILE" buttons.rows.pins.clock.port)
        index=$(yq r "$PIN_FILE" buttons.rows.pins.clock.index)

        {
            printf "%s\n" "#define SR_IN_CLK_PORT CORE_IO_PORT(${port})"
            printf "%s\n" "#define SR_IN_CLK_PIN CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        port=$(yq r "$PIN_FILE" buttons.rows.pins.latch.port)
        index=$(yq r "$PIN_FILE" buttons.rows.pins.latch.index)

        {
            printf "%s\n" "#define SR_IN_LATCH_PORT CORE_IO_PORT(${port})"
            printf "%s\n" "#define SR_IN_LATCH_PIN CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"
    elif [[ $(yq r "$PIN_FILE" buttons.rows.type) == "native" ]]
    then
        rows=$(yq r "$PIN_FILE" buttons.rows.pins --length)

        printf "%s\n" "const core::io::mcuPin_t dInPins[$rows] = {" >> "$OUT_FILE_SOURCE"

        for ((i=0; i<rows; i++))
        do
            port=$(yq r "$PIN_FILE" buttons.rows.pins["$i"].port)
            index=$(yq r "$PIN_FILE" buttons.rows.pins["$i"].index)

            {
                printf "%s\n" "#define DIN_PORT_${i} CORE_IO_PORT(${port})"
                printf "%s\n" "#define DIN_PIN_${i} CORE_IO_PORT_INDEX(${index})"
            } >> "$OUT_FILE_HEADER"

            printf "%s\n" "CORE_IO_MCU_PIN_DEF(DIN_PORT_${i}, DIN_PIN_${i})," >> "$OUT_FILE_SOURCE"
        done

        printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
    fi

    for ((i=0; i<3; i++))
    do
        port=$(yq r "$PIN_FILE" buttons.columns.pins.decA"$i".port)
        index=$(yq r "$PIN_FILE" buttons.columns.pins.decA"$i".index)

        {
            printf "%s\n" "#define DEC_BM_PORT_A${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define DEC_BM_PIN_A${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"
    done
fi

if [[ $digital_outputs_indexed -ne 0 ]]
then
    digital_outputs=$digital_outputs_indexed

    printf "%s\n" "const uint8_t ledIndexes[MAX_NUMBER_OF_LEDS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<digital_outputs; i++))
    do
        index=$(yq r "$PIN_FILE" leds.external.indexing["$i"])
        printf "%s\n" "${index}," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
fi

if [[ $digital_out_type == native ]]
then
    printf "%s\n" "const core::io::mcuPin_t dOutPins[MAX_NUMBER_OF_LEDS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<digital_outputs; i++))
    do
        port=$(yq r "$PIN_FILE" leds.external.pins["$i"].port)
        index=$(yq r "$PIN_FILE" leds.external.pins["$i"].index)

        {
            printf "%s\n" "#define DOUT_PORT_${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define DOUT_PIN_${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        printf "%s\n" "CORE_IO_MCU_PIN_DEF(DOUT_PORT_${i}, DOUT_PIN_${i})," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
elif [[ $digital_out_type == shiftRegister ]]
then
    port=$(yq r "$PIN_FILE" leds.external.pins.data.port)
    index=$(yq r "$PIN_FILE" leds.external.pins.data.index)

    {
        printf "%s\n" "#define SR_OUT_DATA_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_OUT_DATA_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" leds.external.pins.clock.port)
    index=$(yq r "$PIN_FILE" leds.external.pins.clock.index)

    {
        printf "%s\n" "#define SR_OUT_CLK_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_OUT_CLK_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" leds.external.pins.latch.port)
    index=$(yq r "$PIN_FILE" leds.external.pins.latch.index)

    {
        printf "%s\n" "#define SR_OUT_LATCH_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_OUT_LATCH_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" leds.external.pins.enable.port)
    index=$(yq r "$PIN_FILE" leds.external.pins.enable.index)

    {
        printf "%s\n" "#define SR_OUT_OE_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define SR_OUT_OE_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
elif [[ $digital_out_type == matrix ]]
then
    for ((i=0; i<3; i++))
    do
        port=$(yq r "$PIN_FILE" leds.external.columns.pins.decA"$i".port)
        index=$(yq r "$PIN_FILE" leds.external.columns.pins.decA"$i".index)

        {
            printf "%s\n" "#define DEC_LM_PORT_A${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define DEC_LM_PIN_A${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"
    done

    rows=$(yq r "$PIN_FILE" leds.external.rows.pins --length)
    printf "%s\n" "const core::io::mcuPin_t dOutPins[$rows] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<"$rows"; i++))
    do
        port=$(yq r "$PIN_FILE" leds.external.rows.pins["$i"].port)
        index=$(yq r "$PIN_FILE" leds.external.rows.pins["$i"].index)

        {
            printf "%s\n" "#define LED_ROW_PORT_${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define LED_ROW_PIN_${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        printf "%s\n" "CORE_IO_MCU_PIN_DEF(LED_ROW_PORT_${i}, LED_ROW_PIN_${i})," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
fi

if [[ $analog_inputs_indexed -ne 0 ]]
then
    analog_inputs=$analog_inputs_indexed

    printf "%s\n" "const uint8_t analogIndexes[MAX_NUMBER_OF_ANALOG] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<analog_inputs; i++))
    do
        index=$(yq r "$PIN_FILE" analog.indexing["$i"])
        printf "%s\n" "${index}," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
fi

if [[ $analog_in_type == native ]]
then
    printf "%s\n" "const core::io::mcuPin_t aInPins[MAX_ADC_CHANNELS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<analog_inputs; i++))
    do
        port=$(yq r "$PIN_FILE" analog.pins["$i"].port)
        index=$(yq r "$PIN_FILE" analog.pins["$i"].index)

        {
            printf "%s\n" "#define AIN_PORT_${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define AIN_PIN_${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        printf "%s\n" "CORE_IO_MCU_PIN_DEF(AIN_PORT_${i}, AIN_PIN_${i})," >> "$OUT_FILE_SOURCE"
    done

        printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
elif [[ $analog_in_type == 4067 ]]
then
    printf "%s\n" "const core::io::mcuPin_t aInPins[MAX_ADC_CHANNELS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<4; i++))
    do
        port=$(yq r "$PIN_FILE" analog.pins.s"$i".port)
        index=$(yq r "$PIN_FILE" analog.pins.s"$i".index)

        {
            printf "%s\n" "#define MUX_PORT_S${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define MUX_PIN_S${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"
    done

    number_of_mux=$(yq r "$PIN_FILE" analog.multiplexers $PIN_FILE)

    for ((i=0; i<"$number_of_mux"; i++))
    do
        port=$(yq r "$PIN_FILE" analog.pins.z"$i".port)
        index=$(yq r "$PIN_FILE" analog.pins.z"$i".index)

        {
            printf "%s\n" "#define MUX_PORT_INPUT_${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define MUX_PIN_INPUT_${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        printf "%s\n" "CORE_IO_MCU_PIN_DEF(MUX_PORT_INPUT_${i}, MUX_PIN_INPUT_${i})," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
elif [[ $analog_in_type == 4051 ]]
then
    printf "%s\n" "const core::io::mcuPin_t aInPins[MAX_ADC_CHANNELS] = {" >> "$OUT_FILE_SOURCE"

    for ((i=0; i<3; i++))
    do
        port=$(yq r "$PIN_FILE" analog.pins.s"$i".port)
        index=$(yq r "$PIN_FILE" analog.pins.s"$i".index)

        {
            printf "%s\n" "#define MUX_PORT_S${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define MUX_PIN_S${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"
    done

    number_of_mux=$(yq r "$PIN_FILE" analog.multiplexers $PIN_FILE)

    for ((i=0; i<"$number_of_mux"; i++))
    do
        port=$(yq r "$PIN_FILE" analog.pins.z"$i".port)
        index=$(yq r "$PIN_FILE" analog.pins.z"$i".index)

        {
            printf "%s\n" "#define MUX_PORT_INPUT_${i} CORE_IO_PORT(${port})"
            printf "%s\n" "#define MUX_PIN_INPUT_${i} CORE_IO_PORT_INDEX(${index})"
        } >> "$OUT_FILE_HEADER"

        printf "%s\n" "CORE_IO_MCU_PIN_DEF(MUX_PORT_INPUT_${i}, MUX_PIN_INPUT_${i})," >> "$OUT_FILE_SOURCE"
    done

    printf "%s\n" "};" >> "$OUT_FILE_SOURCE"
fi

printf "\n%s" "}" >> "$OUT_FILE_SOURCE"

if [[ $(yq r "$PIN_FILE" bootloader.button) != "" ]]
then
    port=$(yq r "$PIN_FILE" bootloader.button.port)
    index=$(yq r "$PIN_FILE" bootloader.button.index)

    {
        printf "%s\n" "#define BTLDR_BUTTON_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define BTLDR_BUTTON_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
elif [[ $(yq r "$PIN_FILE" bootloader.buttonIndex) != "" ]]
then
    index=$(yq r "$PIN_FILE" bootloader.buttonIndex)

    {
        printf "%s\n" "#define BTLDR_BUTTON_INDEX CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
fi

if [[ $(yq r "$PIN_FILE" bootloader.led) != "" ]]
then
    port=$(yq r "$PIN_FILE" bootloader.led.port)
    index=$(yq r "$PIN_FILE" bootloader.led.index)

    {
        printf "%s\n" "#define BTLDR_LED_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define BTLDR_LED_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
fi

if [[ $(yq r "$PIN_FILE" leds.internal.pins.din) != "" ]]
then
    port=$(yq r "$PIN_FILE" leds.internal.pins.din.rx.port)
    index=$(yq r "$PIN_FILE" leds.internal.pins.din.rx.index)

    {
        printf "%s\n" "#define LED_MIDI_IN_DIN_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define LED_MIDI_IN_DIN_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" leds.internal.pins.din.tx.port)
    index=$(yq r "$PIN_FILE" leds.internal.pins.din.tx.index)

    {
        printf "%s\n" "#define LED_MIDI_OUT_DIN_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define LED_MIDI_OUT_DIN_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
fi

if [[ $(yq r "$PIN_FILE" leds.internal.pins.usb) != "" ]]
then
    port=$(yq r "$PIN_FILE" leds.internal.pins.usb.rx.port)
    index=$(yq r "$PIN_FILE" leds.internal.pins.usb.rx.index)

    {
        printf "%s\n" "#define LED_MIDI_IN_USB_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define LED_MIDI_IN_USB_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"

    port=$(yq r "$PIN_FILE" leds.internal.pins.usb.tx.port)
    index=$(yq r "$PIN_FILE" leds.internal.pins.usb.tx.index)

    {
        printf "%s\n" "#define LED_MIDI_OUT_USB_PORT CORE_IO_PORT(${port})"
        printf "%s\n" "#define LED_MIDI_OUT_USB_PIN CORE_IO_PORT_INDEX(${index})"
    } >> "$OUT_FILE_HEADER"
fi

printf "\n%s" "#include \"board/common/Map.cpp.include\"" >> "$OUT_FILE_SOURCE"