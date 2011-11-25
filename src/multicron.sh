#!/bin/bash

# MultiCron: A better way to manage cron jobs for applications

# Determines whether the first argument is a factor of the second argument
function is_a_factor {

	quotient=$(echo "$2 $1" | awk '{print $1/$2}')
	
	if [[ $quotient == *.* ]]; then
		echo 0
	else
		echo 1
	fi

}

# Determines where a value (e.g. "4") matches a single cron-like pattern (e.g. "15", "*/3", "1,2,*/4", etc)
function matches_pattern {

	value="$1"
	pattern="$2"
	
	pattern=$(echo "$pattern" | tr -d [:space:])
	patterns=$(echo "$pattern" | tr ',' '\n')
	
	# Check for the existence of any asterisks
	asterisk_count=$(echo "$patterns" | grep "^\*$" | wc -l)
	
	if [[ $asterisk_count -gt 0 ]]; then
		echo 1
		exit
	fi
	
	# Find all patterns that are either integers or ranges (e.g. 3-6) and format them for use in a case statement (e.g. [3-6] ) 
	case_patterns=$(echo "$patterns" | grep "^[0-9-]\{1,\}$" | sed 's/\([0-9]\{1,\}-[0-9]\{1,\}\)/[\1]/g' | sed 's/\($\)/\1 \) echo 1; exit ;;/')
	
	# Check whether the value matches any of the integer or range patterns
	eval "
		case ${value} in
			${case_patterns}
		esac
	"
	
	# Find all asterisk/integer patterns (e.g. */2) and remove the "*/" to leave just the integer
	divisors=$(echo "$patterns" | grep "^\*\/[0-9]\{1,\}$" | sed 's/[^0-9]\{1,\}//g')
	
	# Check whether the value is a factor of any of the divisors
	echo "${divisors}" | while read divisor; do
		if [ -n "$divisor" ]; then
			if [ $(is_a_factor $divisor $value) -eq 1 ]; then
				echo 1
				exit
			fi
		fi
	done
	
	echo 0
	exit

}

# Takes two arguments: a date formatted like a crontab pattern (e.g. $(date '+%M %k %e %m %w')) and
# a crontab pattern (e.g. "* * * * *"), and returns whether the date matches the pattern
function date_matches_date_pattern {

	date_values="$1"
	pattern_values="$2"

	while [ -n "$date_values" ]; do
		date_value=$(echo "$date_values" | cut -d ' ' -f 1)
		date_values=$(echo "$date_values" | sed 's/[^ ]* *\(.*\)$/\1/')
		pattern_value=$(echo "$pattern_values" | cut -d ' ' -f 1)
		pattern_values=$(echo "$pattern_values" | sed 's/[^ ]* *\(.*\)$/\1/')
		if [ $(matches_pattern "$date_value" "$pattern_value") -eq 0 ]; then
			echo 0
			exit
		fi
	done
	
	echo 1
	exit
	
}

# Takes two arguments: a path to a file with crontab-like content, and an optional path that will
# be prepended to the commands that are executed
function process_crontab_file {

	crontab_file="$1"
	app_path="$2"
	
	# Set the current date
	current_date="$min $hour $day_of_month $month $day_of_week"
	current_date=$(date '+%M %k %e %m %w')
	# Remove leading zeroes
	current_date=$(echo $current_date | sed 's/^0//' | sed 's/ 0/ /')
	
	while read line; do
		
		# Skip comments
		first_character=$(echo "$line" | cut -c1)
		if [ "$first_character" = "#" ]; then
			continue
		fi
		# Skip empty lines
		line=$(echo "$line")
		if [ -z "$line" ]; then
			continue
		fi
		
		date_pattern=$(echo "$line" | tr [:space:] '\n' | head -5 | tr '\n' ' ')
		command=$(echo "$line" | tr [:space:] '\n' | sed '1,5d' | tr '\n' ' ')
		command=$(echo "$command" | sed "s|\[\[APP_PATH\]\]|$app_path|g")
		# Run the command if its date pattern matches the current date
		if [ $(date_matches_date_pattern "$current_date" "$date_pattern") -eq 1 ]; then
			$($command)
		fi
	
	# Add a newline at the end of the file so that last line is captured in the loop 
	done < <(grep '^' "$crontab_file")

}

# Takes one argument: a file path. If the file path is relative, this script's directory is prepended.
function prepend_current_path_if_relative_path {

	file_path="$1"

	first_character=$(echo "$file_path" | cut -c1)
	# If the file path is a relative path, prepend this script's directory to make it absolute.
	if [ "$first_character" != "/" ]; then
		file_path="$( cd "$( dirname "$0" )" && pwd )/$file_path"
	fi
	echo $file_path
	exit

}

# Grab the options, process them, and run the crontab file(s) accordingly

config_file=""
crontab_files=""
app_paths=""

while getopts ":c:x:p:" opt; do
	case "${opt}" in
		c) config_file="$OPTARG";;
		p) app_paths="$OPTARG";;
		x) crontab_files="$OPTARG";;
		*) ;;
	esac
done

if [ -n "$config_file" ]; then
	config_file="$(prepend_current_path_if_relative_path $config_file)"
	source "$config_file"
fi

crontab_files=$(echo "$crontab_files" | tr ',' '\n')
app_paths=$(echo "$app_paths" | tr ',' '\n')

if [ -z "$crontab_files" ]; then
	echo "Please specify at least one crontab file:"
	echo "./multicron.sh -x \"/path/to/crontab_file.txt\""
	exit
fi

echo "${crontab_files}" | while read crontab_file; do
	if [ -n "$crontab_file" ]; then
		echo "${app_paths}" | while read app_path; do
			if [ -n "$crontab_file" ]; then
				crontab_file="$(prepend_current_path_if_relative_path $crontab_file)"
				process_crontab_file "$crontab_file" "$app_path"
			fi
		done
	fi
done