NAME	= philo

CC		= cc
CFLAGS	= -Wall -Wextra -Werror -I.

SRCS	= main.c \
		  start_diner.c \
		  cleanup.c \
		  monitor.c \
		  cycle/cycle.c \
		  cycle/eat.c \
		  cycle/sleep.c \
		  cycle/think.c \
		  utils/args.c \
		  utils/utils.c

OBJS	= $(SRCS:.c=.o)

all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $(NAME)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS)

fclean: clean
	rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re
