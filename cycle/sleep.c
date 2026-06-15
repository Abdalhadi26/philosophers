/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   sleep.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/15 10:28:10 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:53:55 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

void	sleepy(t_philo *philo)
{
	print_action(philo, "is sleeping");
	go_sleep(philo->diner->tt_sleep, philo);
}
