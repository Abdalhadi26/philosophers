/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   cleanup.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/14 20:22:13 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:52:32 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

void	free_and_destory(t_diner *diner)
{
	int	i;

	pthread_mutex_destroy(&diner->print_lock);
	pthread_mutex_destroy(&diner->is_dinning_lock);
	i = 0;
	while (i < diner->n_philos)
	{
		pthread_mutex_destroy(&diner->forks[i]);
		pthread_mutex_destroy(&diner->philos[i].meals_lock);
		i++;
	}
	free(diner->philos);
	free(diner->forks);
}
