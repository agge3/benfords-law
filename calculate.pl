#!/usr/bin/env perl

use strict;
use warnings;
use POSIX qw(log);
use Text::Table;

# Function to parse the CSV file and store data in a hash.
sub parse_csv {
    my $file = shift or die "Usage: $0 <csv_file>\n";

    # Open the CSV file for reading.
    open my $fh, '<', $file or die "Could not open '$file': $!\n";

    # Hash to store the data.
    my %data;

    # Read each line of the file.
    while (my $line = <$fh>) {
        chomp $line;

        # Skip empty lines.
        next if $line =~ /^\s*$/;

        # Split the line by comma (it's a CSV, this is the expected input).
		# Can change these variables to have different column CSVs.
        my ($name, $code, $population) = split /,/, $line;

        # Skip lines with missing data.
        next unless defined $code && defined $population;

        # Store the data in the hash with country code as the key.
        $data{$code} = [$population, $name];
    }

    # Close the file handle.
    close $fh;

    return \%data; # Return the hash reference.
}

sub count_leading_digits {
    my ($data) = @_;

    # Hash to count occurrences of leading digits.
    my %digit_count;
    my $total = 0;

    # Process each population to count leading digits.
    foreach my $code (keys %{$data}) {
        my $population = $data->{$code}->[0];

        # Ensure population is numeric.
        $population =~ s/[^\d]//g;

        # Strip leading digit and count occurrences.
        if ($population =~ /^(\d)/) {
            my $leading_digit = $1;
            $digit_count{$leading_digit}++;
            $total++;
        }
    }

    # Return a hash reference with digit counts and total count.
    return {
        digit_count => \%digit_count,
        total => $total,
    };
}

sub calculate_frequency {
    my ($digit_count, $total_count) = @_;

    # Hash to store the frequency of each digit.
    my %frequency;

    # Calculate frequency for each digit.
    foreach my $digit (keys %{$digit_count}) {
        if ($total_count > 0) {
            $frequency{$digit} = ($digit_count->{$digit} / $total_count) * 100;
        } else {
            $frequency{$digit} = 0;  # Handle case where total count is zero.
        }
    }

    # Return a hash reference with the frequencies.
    return \%frequency;
}

sub calculate_benfords_law {
    my %benfords_law;
    foreach my $digit (1..9) { # Digits should be from 1 to 9.
        my $log_d = log($digit); # Natural log of digit.
        my $log_d1 = log($digit + 1); # Natural log of digit + 1.
        $benfords_law{$digit} = ( $log_d1 - $log_d ) / log(10); # Log base 10.
        $benfords_law{$digit} = $benfords_law{$digit} * 100; # Percentage.
    }
    return \%benfords_law;
}

# Main entry:
my $file = shift @ARGV or die "Usage: $0 <csv_file>\n";

# Parse the CSV file.
my $data = parse_csv($file);

# Count leading digits.
my $results = count_leading_digits($data);
my $digit_counts = $results->{digit_count};
my $total_count = $results->{total};

# Calculate frequencies.
my $frequencies = calculate_frequency($digit_counts, $total_count);

# Calculate Benford's Law expected frequencies.
my $benfords_law = calculate_benfords_law();

# Create and populate the table.
my $table = Text::Table->new(
    "First Digit", "Frequency", "Percent Frequency", "Expected Percent Frequency"
);

foreach my $digit (sort { $a <=> $b } keys %{$digit_counts}) {
    my $freq = $digit_counts->{$digit};
	my $percent_freq = $frequencies->{$digit};
    my $expected_percent = $benfords_law->{$digit};

    $table->add(
        $digit,
        $freq,
        sprintf("%.2f%%", $percent_freq),
        sprintf("%.2f%%", $expected_percent)
    );
}

# Print the table
print $table;
