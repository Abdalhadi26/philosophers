/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   start_diner.c                                      :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/13 19:59:49 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/14 20:21:25 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

static void	destory_locks_so_far(t_diner *diner,int n)
{
	int i;

	pthread_mutex_destroy(&diner->print_lock);
	pthread_mutex_destroy(&diner->simulation_end_lock);
	i = 0;
	while (i < n)
	{
		pthread_mutex_destroy(&diner->forks[i]);
		i++;
	}
}


int init_diner_locks(t_diner *diner)
{
	int	i;
	
	if (pthread_mutex_init(&diner->print_lock, NULL) != SUCCESS)
		return (FAILURE);
	if (pthread_mutex_init(&diner->simulation_end_lock, NULL) != SUCCESS)
	{
		pthread_mutex_destroy(&diner->print_lock);
		return (FAILURE);
	}
	i = 0;
	while (i < diner->n_philos)
	{
		if (pthread_mutex_init(&diner->forks[i], NULL) != SUCCESS)
		{
			destory_locks_so_far(diner, i);
			return (FAILURE);
		}
		i++;
	}
	return (SUCCESS);
}

int init_philos(t_diner *diner)
{
	int	i;

	i = 0;
	while (i < diner->n_philos)
	{
		diner->philos[i].id = i + 1;
		diner->philos[i].meals_eaten = 0;
		diner->philos[i].last_meal_time = 0;
		diner->philos[i].diner = diner;
		if (i == diner->n_philos - 1)
			diner->philos[i].right_fork = &diner->forks[0];
		else
			diner->philos[i].right_fork = &diner->forks[i + 1];
		diner->philos[i].left_fork = &diner->forks[i];
		if (pthread_mutex_init(&diner->philos[i].meals_lock, NULL) != SUCCESS)
			return (FAILURE);
		i++;
	}
	return (SUCCESS);
}

int init_diner(t_diner *diner)
{
	diner->philos = malloc(sizeof(t_philo) * diner->n_philos);
	if (!diner->philos)
		return (FAILURE);
	diner->forks = malloc(sizeof(pthread_mutex_t) * diner->n_philos);
	if (!diner->forks)
	{
		free(diner->philos);
		return (FAILURE);
	}
	if (init_diner_locks(diner) == FAILURE)
	{
		free(diner->philos);
		free(diner->forks);
		return (FAILURE);
	}
	if (init_philos(diner) == FAILURE)
	{
		free(diner->philos);
		free(diner->forks);
		return (FAILURE);
	}
	return (SUCCESS);
}

int	start_diner(t_diner *diner)
{
	int	i;

	if (init_diner(diner) == FAILURE)
		return (FAILURE);
	i = 0;
	while (i < diner->n_philos)
	{
		if (pthread_create(&diner->philos[i].thread, NULL, cycle, &diner->philos[i]) != SUCCESS)
		{
			//free and close all
			return (FAILURE);
		}
		i++;
	}
	//mointor
	return (SUCCESS);
}
