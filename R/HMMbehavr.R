#' @title HMMbehavr
#' @description This function runs a Hidden Markov Model (HMM) on behavioral data.
#' @param behavtbl A data frame containing the behavioral data, conforming to a \code{behavr} table.
#' @param it Integer (>= 100) specifying the number of iterations for the HMM fitting process. Defaults to 100.
#' @param ldcyc A single numeric value specifying the duration of the light phase in hours. If NULL (default), a 12-hour light/12-hour dark cycle is assumed.
#' @return A list containing data frames:
#'   \item{TimeSpentInEachState}{Time spent in each inferred state.}
#'   \item{VITERBIDecodedProfile}{The most likely sequence of hidden states (Viterbi path).}
#' @examples
#' res1 <- HMMbehavr(behavtbl = dt_test, it = 100, ldcyc = 10) # 10 hours light, 100 iterations
#' @export
HMMbehavr <- function(behavtbl, it = 100, ldcyc = NULL) {
  # validate + clamp iterations
  if (!(is.numeric(it) && length(it) == 1L && is.finite(it) && it == as.integer(it))) {
    stop("'it' must be a single integer.", call. = FALSE)
  }
  it <- as.integer(it)
  if (it < 100L) {
    # nice styled message (optional)
    if (requireNamespace("cli", quietly = TRUE)) {
      cli::cli_alert_warning("`it` ({it}) is < 100; using 100 instead.")
    }
    it <- 100L
  }

  tryCatch(
    {
      tictoc::tic("HMMbehavr")

      # Initialize data frames to store results across all individuals and days
      time_spent_all_states <- data.frame()
      profile_all_states <- data.frame()
      transitions_all_states <- data.frame()
      # This data frame will now correctly store all failed cases
      failed_cases <- data.frame(ID = character(), Day = numeric(), ErrorMessage = character(), stringsAsFactors = FALSE)

      dt_hmm <- behavtbl
      total_iterations <- length(unique(dt_hmm$id)) * length(unique(dt_hmm$day)) * it

      # Set up a progress bar
      cli::cli_progress_bar(
        total = total_iterations,
        format = "Fitting HMMs {cli::pb_bar} {cli::pb_current}/{cli::pb_total} {cli::pb_percent} | [{cli::pb_elapsed}] | ETA: {cli::pb_eta}"
      )

      # Iterate through each unique individual ID
      for (individual_id in unique(dt_hmm$id)) {
        # Iterate through each unique day
        for (day_number in unique(dt_hmm$day)) {
          tryCatch(
            {
              # Filter data for the current individual and day
              dt_individual_day <- dt_hmm %>% dplyr::filter(id == individual_id & day == day_number)
              dt_processed <- dt_individual_day
              k <- 4

              # Prepare data for HMM: select time and normalized activity
              hmm_data <- as.data.frame(dt_processed[, c("t", "normact")])

              # Replace zero values with a small value unlikely to occur naturally, to avoid issues with Gaussian distribution
              # This is due to likelihood errors caused by zero SD in one state in depmixS4
              hmm_data$normact <- ifelse(hmm_data$normact == 0, 1e-03, hmm_data$normact)
              activity_data <- hmm_data$normact

              # Initialize data frames for results within the current individual and day
              profile_iterations <- data.frame()
              transitions_iterations <- data.frame()

              # Run the HMM for the specified number of iterations
              for (iteration in 1:it) {
                cli::cli_progress_update()
                inner_counter <- 0
                max_inner_iterations <- 1000 # Use the parameter value

                # Ensure iteration_results is not carried over from a previous failed attempt
                if (exists("iteration_results", inherits = FALSE)) {
                  rm(iteration_results)
                }

                # Repeat fitting until a valid solution with k states is found or max iterations reached
                repeat {
                  inner_counter <- inner_counter + 1
                  tryCatch(
                    {
                      num_states <- k
                      upper_boundary_rows <- 1
                      lower_boundary_rows <- 1
                      middle_rows <- num_states - 2
                      epsilon <- 1e-5 # Small probability for transitions to non-adjacent states

                      # Define the initial transition probability matrix (sparse structure)
                      transition_matrix <- matrix(
                        c(
                          rep(c(rep(((1 - (2 * epsilon)) / (num_states - 1)),
                            times = (num_states - 1)
                          ), epsilon), times = upper_boundary_rows),
                          (tryCatch(rep(rep((1 / num_states), num_states), middle_rows),
                            error = function(e) NULL
                          )),
                          rep(c(epsilon, rep(((1 - (2 * epsilon)) / (num_states - 1)),
                            times = (num_states - 1)
                          )), times = lower_boundary_rows)
                        ),
                        nrow = num_states, ncol = num_states,
                        byrow = TRUE
                      )

                      # Define the initial state probability vector (uniform distribution)
                      initial_prob_matrix <- rep((1 / (num_states)), num_states)

                      # Define the Hidden Markov Model using depmixS4 package
                      model <- depmixS4::depmix(
                        response = activity_data ~ 1, data = data.frame(activity_data),
                        nstates = num_states, trstart = transition_matrix,
                        instart = initial_prob_matrix, family = gaussian()
                      )

                      # Fit the HMM
                      fitted_model <- tryCatch(
                        depmixS4::fit(model,
                          verbose = FALSE,
                          emcontrol = depmixS4::em.control(
                            classification = "soft",
                            random.start = TRUE
                          )
                        ),
                        error = function(e) NULL
                      )

                      # If the model fitting was successful
                      if (!is.null(fitted_model)) {
                        # Get the Viterbi path (most likely sequence of states)
                        viterbi_path <- depmixS4::posterior(fitted_model, type = "viterbi")
                        ordered_states <- viterbi_path
                        ordered_states$state <- paste0("S", ordered_states$state)
                        ordered_states$normact <- activity_data

                        # Summarize activity within each inferred state to order them
                        state_summary <- ordered_states %>%
                          dplyr::group_by(state) %>%
                          dplyr::summarise(median_activity = median(normact), .groups = "drop") %>%
                          dplyr::arrange(dplyr::desc(median_activity))

                        # Assign a more descriptive name to each state based on activity level
                        state_summary$state_name <- paste0("State", seq(0, nrow(state_summary) - 1))
                        state_summary <- state_summary[order(state_summary$state), ]

                        # Map the ordered state names back to the Viterbi path
                        viterbi_path$state <- paste0("S", viterbi_path$state)
                        viterbi_path$state_name <- state_summary$state_name[match(viterbi_path$state, state_summary$state)]

                        # Assign light and dark phases based on ldcyc parameter
                        if (!is.null(ldcyc) && is.numeric(ldcyc) && length(ldcyc) == 1) {
                          light_duration_hours <- ldcyc
                          viterbi_path$phase <- ifelse(hmm_data$t %% behavr::hours(24) < behavr::hours(light_duration_hours),
                            "light", "dark"
                          )
                        } else {
                          # Default: 12 hours light
                          light_duration_hours <- 12
                          viterbi_path$phase <- ifelse(hmm_data$t %% behavr::hours(24) < behavr::hours(light_duration_hours),
                            "light", "dark"
                          )
                        }
                        viterbi_path$timestamp <- seq_len(nrow(viterbi_path))
                        viterbi_path$normact <- activity_data

                        # Calculate time spent in each state
                        time_in_states <- viterbi_path %>%
                          dplyr::select(state, state_name, phase) %>%
                          dplyr::group_by(state_name, phase) %>%
                          dplyr::summarise(time_spent = dplyr::n() * 1, .groups = "drop")

                        # Calculate transitions between states
                        states_sequence <- viterbi_path$state_name
                        transition_table <- table(states_sequence[-length(states_sequence)], states_sequence[-1])
                        transitions <- reshape2::melt(transition_table)

                        # Store the results for the current iteration
                        iteration_results <- list(time_in_states, viterbi_path, transitions)

                        # Break the inner loop if a solution with the correct number of states is found
                        if (length(unique(iteration_results[[1]]$state_name)) == k) {
                          break
                        }
                      }
                    },
                    error = function(e) NULL
                  )

                  # Break the inner loop if the maximum number of inner iterations is reached
                  if (inner_counter >= max_inner_iterations) {
                    cli::cli_alert_info(
                      cli::style_bold(cli::col_red("Maximum inner iterations (", max_inner_iterations, ") reached without meeting the condition for ID:", individual_id, "Day:", day_number))
                    )
                    break
                  }
                } # End of repeat loop

                # If a valid solution was found in the inner loop, add it to the collection
                if (exists("iteration_results", inherits = FALSE)) {
                  iteration_results[[2]]$ID <- individual_id
                  iteration_results[[2]]$Genotype <- as.character(unique(dt_individual_day$genotype))
                  iteration_results[[2]]$day <- day_number
                  iteration_results[[2]]$iter <- iteration
                  profile_iterations <- rbind(profile_iterations, iteration_results[[2]])

                  iteration_results[[3]]$ID <- individual_id
                  iteration_results[[3]]$Genotype <- as.character(unique(dt_individual_day$genotype))
                  iteration_results[[3]]$day <- day_number
                  iteration_results[[3]]$iter <- iteration
                  transitions_iterations <- rbind(transitions_iterations, iteration_results[[3]])
                }
              } # End of iteration loop

              # Summarize results ONLY if at least one iteration was successful.
              if (nrow(profile_iterations) > 0) {
                profile_summary <- profile_iterations %>%
                  dplyr::group_by(timestamp, phase, day, ID, Genotype) %>%
                  dplyr::count(state_name) %>%
                  dplyr::slice(which.max(n)) %>%
                  dplyr::mutate(error_score = (1 - (n / it)) * 100) %>%
                  dplyr::ungroup()

                # ===== Single-state dominance check on profile_summary =====
                # Count how many timestamps are in each state for this day
                state_counts <- table(profile_summary$state_name)
                total_points <- sum(state_counts)
                max_prop <- max(state_counts) / total_points

                if (total_points == 1440 && max_prop > 0.99) {
                  msg <- paste0(
                    "Single-state dominance (>99%) detected for ID ", individual_id,
                    " on day ", day_number, ". Excluding this day."
                  )
                  cli::cli_alert_warning(msg)

                  failed_cases <- rbind(
                    failed_cases,
                    data.frame(
                      ID = individual_id,
                      Day = day_number,
                      ErrorMessage = "Excluded: >99% of 1440 minutes in one state",
                      stringsAsFactors = FALSE
                    )
                  )

                  # Skip adding this day’s results to the final data frames
                  next
                }
                # ===== end check =====

                profile_all_states <- rbind(profile_all_states, profile_summary)

                time_spent_summary <- profile_summary %>%
                  dplyr::select(state_name, phase, ID, day, Genotype) %>%
                  dplyr::group_by(state_name, phase, ID, day, Genotype) %>%
                  dplyr::summarise(time_spent = dplyr::n() * 1, .groups = "drop")
                time_spent_all_states <- rbind(time_spent_all_states, time_spent_summary)
              } else {
                # If profile_iterations is empty, it means NO iteration succeeded. Log it as a failed case.
                failed_cases <- rbind(failed_cases, data.frame(
                  ID = individual_id,
                  Day = day_number,
                  ErrorMessage = paste("No valid solution found after", it, "iterations."),
                  stringsAsFactors = FALSE
                ))
              }
            },
            error = function(e) {
              # This part catches other, more general errors.
              cli::cli_alert_danger(
                cli::style_bold(cli::col_red("Error processing ID:", individual_id, "Day:", day_number, " - ", e$message))
              )
              failed_cases <- rbind(failed_cases, data.frame(
                ID = individual_id,
                Day = day_number,
                ErrorMessage = e$message,
                stringsAsFactors = FALSE
              ))
            }
          ) # End of inner tryCatch
        } # End of day loop
      } # End of individual loop

      # Ensure all state-phase combinations are present in the time spent data
      time_spent_all_states <- time_spent_all_states %>%
        dplyr::group_by(Genotype, ID, day) %>%
        tidyr::complete(
          # phase = unique(time_spent_all_states$phase),
          # state_name = unique(time_spent_all_states$state_name),
          phase = c("light", "dark"),
          state_name = c("State0", "State1", "State2", "State3"),
          fill = list(time_spent = 0)
        )

      # Remove quality control columns from final profile dataframe
      profile_all_states <- profile_all_states %>%
        dplyr::select(-c(n, error_score))

      tictoc::toc()

      # This final check will now correctly display all collected errors.
      if (nrow(failed_cases) > 0) {
        cli::cli_alert_warning("The following IDs and Days failed to produce a valid HMM solution and were excluded:")
        print(failed_cases)
      }

      # Return the results as a list of data frames
      return(list(
        TimeSpentInEachState = time_spent_all_states,
        VITERBIDecodedProfile = profile_all_states
      ))
    },
    error = function(e) {
      # This is a catch-all for any other unexpected error in the function.
      cli::cli_alert_danger(paste("A critical error occurred:", e$message))
      return(NULL)
    }
  ) # End of outer tryCatch
}
