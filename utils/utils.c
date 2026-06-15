/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   utils.c                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/14 12:43:29 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:54:15 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

void	ft_putstr_fd(char *s, int fd)
{
	if (!s)
		return ;
	while (*s)
	{
		write(fd, s, 1);
		s++;
	}
}

long long	get_time(void)
{
	long long		time;
	struct timeval	tv;

	gettimeofday(&tv, NULL);
	time = tv.tv_sec * 1000 + tv.tv_usec / 1000;
	return (time);
}

void	go_sleep(long long duration, t_philo *philo)
{
	long long	start_time;

	start_time = get_time();
	while (get_time() - start_time < duration)
	{
		usleep(20);
		if (!is_dinning(philo->diner))
			return ;
	}
}

void	print_action(t_philo *philo, char *state)
{
	pthread_mutex_lock(&philo->diner->print_lock);
	if (!is_dinning(philo->diner))
	{
		pthread_mutex_unlock(&philo->diner->print_lock);
		return ;
	}
	printf("%lld\t%d %s\n", get_time() - philo->diner->start_time, philo->id,
		state);
	pthread_mutex_unlock(&philo->diner->print_lock);
}
