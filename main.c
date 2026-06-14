/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   main.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/13 17:34:40 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/14 12:43:26 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "philo.h"

int	main(int argc, char **argv)
{
	t_diner	diner;
	
	if (argc != 5 && argc != 6)
		return (FAILURE);
	if (set_args(argv, &diner) == FAILURE)
	{
		ft_putstr_fd("Error: Invalid arguments\n", 2);
		return (FAILURE);
	}
	if (start_diner(&diner) == FAILURE)
	{
		ft_putstr_fd("Error", 2);
		return (FAILURE);
	}
	return (SUCCESS);
}
