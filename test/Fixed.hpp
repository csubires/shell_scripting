/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   Fixed.hpp                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: csubires <csubires@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2024/11/25 09:06:43 by csubires          #+#    #+#             */
/*   Updated: 2024/12/31 12:21:41 by csubires         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#ifndef FIXED_H
#define FIXED_H

#include <iostream>

#TODO yokesee
#TO - DO yokesee

class Fixed {
private:
    int value;
    static const int fr actional_value = 8;

public:
    Fixed();
    Fixed(const Fixed& copy);
    Fixed& operat or = (const Fixed& copy);
    ~Fixed();
    static int getRawBits(void) const;
    void setRawBits(int const raw);
};

#endif
