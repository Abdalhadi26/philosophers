/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   philo.h                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/13 12:20:53 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/14 19:50:52 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

# include <limits.h>
# include <pthread.h>
# include <stdio.h>
# include <stdlib.h>
# include <sys/time.h>
# include <unistd.h>

typedef struct s_philo t_philo;

typedef enum e_code
{
	SUCCESS,
	FAILURE
}	t_code;

typedef struct s_diner
{
	int				n_philos;
	long long		tt_die;
	long long		tt_eat;
	long long		tt_sleep;
	int				min_meals;
	int				simulation_end;
	pthread_mutex_t simulation_end_lock;
	pthread_mutex_t	print_lock;
	t_philo			*philos;
	pthread_mutex_t	*forks;
}					t_diner;

typedef struct s_philo
{
	int				id;
	int				meals_eaten;
	long long		last_meal_time;
	pthread_mutex_t	meals_lock; //to lock meals_eaten and last_meal_time
	pthread_t		thread;
	pthread_mutex_t	*right_fork;
	pthread_mutex_t	*left_fork;
	t_diner			*diner;
}					t_philo;

long long	ft_atol(const char *str);
int			set_args(char **argv, t_diner *diner);
void		ft_putstr_fd(char *s, int fd);

int			init_philos(t_diner *diner);
int			init_diner(t_diner *diner);
int			start_diner(t_diner *diner);

void		*cycle(void *arg);

