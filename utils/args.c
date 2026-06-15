/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   args.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/13 16:31:41 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:54:47 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

static int	ft_isdigit(int c)
{
	if (c >= '0' && c <= '9')
		return (1);
	return (0);
}

long long	ft_atol(const char *str)
{
	long long	result;
	int			i;

	i = 0;
	result = 0;
	while (str[i] == 32 || (str[i] >= 9 && str[i] <= 13))
		i++;
	if (str[i] == '+')
		i++;
	while (ft_isdigit(str[i]))
	{
		result *= 10;
		result += str[i] - '0';
		i++;
	}
	return (result);
}

static int	is_valid_number(char *arg)
{
	int	i;

	i = 0;
	while (arg[i] == ' ')
		i++;
	if (arg[i] == '+')
		i++;
	if (!arg[i])
		return (0);
	while (arg[i])
	{
		if (!ft_isdigit(arg[i]))
			return (0);
		i++;
	}
	return (1);
}

int	set_args(char **argv, t_diner *diner)
{
	int	i;

	i = 1;
	while (argv[i])
	{
		if (!is_valid_number(argv[i]))
			return (FAILURE);
		if (ft_atol(argv[i]) > INT_MAX)
			return (FAILURE);
		i++;
	}
	diner->n_philos = (int)ft_atol(argv[1]);
	diner->tt_die = ft_atol(argv[2]);
	diner->tt_eat = ft_atol(argv[3]);
	diner->tt_sleep = ft_atol(argv[4]);
	if (argv[5])
		diner->min_meals = (int)ft_atol(argv[5]);
	else
		diner->min_meals = -1;
	if (diner->n_philos <= 0 || diner->tt_die < 60 || diner->tt_eat < 60
		|| diner->tt_sleep < 60 || (argv[5] && diner->min_meals == 0))
		return (FAILURE);
	return (SUCCESS);
}
