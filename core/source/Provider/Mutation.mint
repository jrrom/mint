/* Represents a subscription for `Provider.Mutation` */
record Provider.Mutation.Subscription {
  changes : Function(Promise(Void)),
  element : Maybe(Dom.Element)
}

/*
A provider to provide events when the DOM structure of the given
element changes.
*/
provider Provider.Mutation : Provider.Mutation.Subscription {
  /* Keep a state of all observed elements. */
  state observedElements : Array(Maybe(Dom.Element)) = []

  /* The mutation observer. */
  state observer = MutationObserver.new(notify)

  /* Notifies the subscribers when changes occur. */
  fun notify (entries : Array(MutationObserver.Entry)) : Array(Array(Promise(Void))) {
    for entry of entries {
      for subscription of subscriptions {
        case subscription.element {
          Maybe::Just(element) =>
            if Dom.contains(element, entry.target) {
              subscription.changes()
            } else {
              next { }
            }

          Maybe::Nothing => next { }
        }
      }
    }
  }

  /* Updates the provider. */
  fun update : Promise(Void) {
    /* Unobserve all elements. */
    for element of Array.compact(observedElements) {
      MutationObserver.unobserve(observer, element)
    }

    /* For each subscription observe the given elements. */
    for subscription of subscriptions {
      case subscription.element {
        Maybe::Just(element) =>
          {
            MutationObserver.observe(observer, element, true, true)
            subscription.changes()
          }

        Maybe::Nothing => next { }
      }
    }

    /* Update the observed elements array. */
    next
      {
        observedElements:
          for subscription of subscriptions {
            subscription.element
          }
      }
  }
}
