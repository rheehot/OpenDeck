/*
    OpenDeck MIDI platform firmware
    Copyright (C) 2015-2017 Igor Petrovic

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma once

///
/// \brief Length of temporary (message) text on display in milliseconds.
///
#define LCD_MESSAGE_DURATION                1500

///
/// \brief Time in milliseconds after text on display is being refreshed.
///
#define LCD_REFRESH_TIME                    10

///
/// \brief Time in milliseconds after which scrolling text moves on display.
///
#define LCD_SCROLL_TIME                     1000

///
/// \brief Maximum amount of characters displayed in single LCD row.
/// Real width is determined later based on display type.
///
#define LCD_WIDTH_MAX                       32

///
/// \brief Maximum number of LCD rows.
/// Real height is determined later based on display type.
///
#define LCD_HEIGHT_MAX                      4

///
/// \brief Array holding remapped values of LCD rows.
/// Tto increase readability every second row is used.
///
const uint8_t rowMap[LCD_HEIGHT_MAX] =
{
    0,
    1,
    2,
    3
};