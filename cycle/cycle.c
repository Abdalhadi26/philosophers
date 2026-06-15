/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   cycle.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/14 11:01:33 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:53:47 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

int	is_dinning(t_diner *diner)
{
	pthread_mutex_lock(&diner->is_dinning_lock);
	if (diner->is_dinning == 0)
	{
		pthread_mutex_unlock(&diner->is_dinning_lock);
		return (0);
	}
	pthread_mutex_unlock(&diner->is_dinning_lock);
	return (1);
}

int	single_philo(t_philo *philo)
{
	if (philo->diner->n_philos == 1)
	{
		pthread_mutex_lock(philo->left_fork);
		print_action(philo, "has taken a fork");
		go_sleep(philo->diner->tt_die, philo);
		pthread_mutex_unlock(philo->left_fork);
		return (1);
	}
	return (0);
}

void	*cycle(void *ptr)
{
	t_philo	*philo;

	philo = (t_philo *)ptr;
	if (single_philo(philo))
		return (NULL);
	if (philo->id % 2 == 0)
		usleep(1000);
	while (is_dinning(philo->diner))
	{
		eaty(philo);
		sleepy(philo);
		thinky(philo);
	}
	return (NULL);
}
