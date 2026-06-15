/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   think.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/15 10:31:29 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 16:48:11 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

void	thinky(t_philo *philo)
{
	print_action(philo, "is thinking");
	go_sleep(10, philo);
}
