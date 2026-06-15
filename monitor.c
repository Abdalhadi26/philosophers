/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   monitor.c                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/15 17:27:00 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:58:45 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

static int	check_starvation(t_diner *diner, int i)
{
	pthread_mutex_lock(&diner->philos[i].meals_lock);
	if (get_time() - diner->philos[i].last_meal_time > diner->tt_die)
	{
		pthread_mutex_unlock(&diner->philos[i].meals_lock);
		print_action(&diner->philos[i], "died");
		zero_out_is_dinning(diner);
		return (1);
	}
	pthread_mutex_unlock(&diner->philos[i].meals_lock);
	return (0);
}

void	join_threads(t_diner *diner, int n)
{
	int	i;

	i = 0;
	while (i < n)
	{
		pthread_join(diner->philos[i].thread, NULL);
		i++;
	}
}

void	zero_out_is_dinning(t_diner *diner)
{
	pthread_mutex_lock(&diner->is_dinning_lock);
	diner->is_dinning = 0;
	pthread_mutex_unlock(&diner->is_dinning_lock);
}

static int	all_philos_filled(t_diner *diner)
{
	int	total;
	int	i;

	total = 0;
	i = 0;
	if (diner->min_meals == -1)
		return (0);
	while (i < diner->n_philos)
	{
		pthread_mutex_lock(&diner->philos[i].meals_lock);
		if (diner->philos[i].meals_eaten >= diner->min_meals)
			total++;
		pthread_mutex_unlock(&diner->philos[i].meals_lock);
		i++;
	}
	if (total == diner->n_philos)
		return (1);
	return (0);
}

void	monitor(t_diner *diner)
{
	int	i;

	while (is_dinning(diner))
	{
		i = 0;
		while (i < diner->n_philos)
		{
			if (check_starvation(diner, i) == 1)
				break ;
			if (all_philos_filled(diner) == 1)
			{
				zero_out_is_dinning(diner);
				break ;
			}
			i++;
		}
		usleep(1);
	}
	join_threads(diner, diner->n_philos);
	free_and_destory(diner);
	return ;
}
