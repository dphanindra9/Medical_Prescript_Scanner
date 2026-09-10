// Apply a desired checkbox state, so retrying a request cannot consume twice.
function applyDose(reminder, key, taken) {
  const doses = { ...reminder.taken_doses };
  const wasTaken = doses[key] === true;
  let count = reminder.pill_count;
  if (taken !== wasTaken) {
    if (taken && count <= 0) {
      const error = new Error('No tablets left in inventory. Add stock first.');
      error.status = 409;
      throw error;
    }
    count += taken ? -1 : 1;
    if (taken) doses[key] = true;
    else delete doses[key];
  }
  const notify = taken && !wasTaken && !reminder.low_stock_notified &&
    reminder.initial_pill_count > 0 && count * 4 <= reminder.initial_pill_count;
  return {
    pill_count: count,
    taken_doses: doses,
    low_stock_notified: reminder.low_stock_notified || notify,
    notify,
  };
}

module.exports = { applyDose };
