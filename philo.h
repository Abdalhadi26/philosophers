/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   philo.h                                            :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: aayasrah <aayasrah@student.42amman.com>    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/13 12:20:53 by aayasrah          #+#    #+#             */
/*   Updated: 2026/06/15 22:55:01 by aayasrah         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <limits.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>

typedef struct s_philo	t_philo;

typedef enum e_code
{
	SUCCESS,
	FAILURE,
}						t_code;

typedef struct s_diner
{
	int					n_philos;
	long long			tt_die;
	long long			tt_eat;
	long long			tt_sleep;
	long long			start_time;
	int					min_meals;
	int					is_dinning;
	pthread_mutex_t		is_dinning_lock;
	pthread_mutex_t		print_lock;
	t_philo				*philos;
	pthread_mutex_t		*forks;
}						t_diner;

typedef struct s_philo
{
	int					id;
	int					meals_eaten;
	long long			last_meal_time;
	pthread_mutex_t		meals_lock;
	pthread_t			thread;
	pthread_mutex_t		*right_fork;
	pthread_mutex_t		*left_fork;
	t_diner				*diner;
}						t_philo;

/* args */
long long	ft_atol(const char *str);
int			set_args(char **argv, t_diner *diner);

/* utils */
void		ft_putstr_fd(char *s, int fd);
long long	get_time(void);
void		go_sleep(long long duration, t_philo *philo);
void		print_action(t_philo *philo, char *state);

/* init / cleanup */
int			init_philos(t_diner *diner);
int			init_diner(t_diner *diner);
int			start_diner(t_diner *diner);
void		free_and_destory(t_diner *diner);

/* simulation state */
int			is_dinning(t_diner *diner);
void		zero_out_is_dinning(t_diner *diner);

/* monitor */
void		monitor(t_diner *diner);
void		join_threads(t_diner *diner, int n);

/* cycle */
void		*cycle(void *arg);
void		eaty(t_philo *philo);
void		sleepy(t_philo *philo);
void		thinky(t_philo *philo);
