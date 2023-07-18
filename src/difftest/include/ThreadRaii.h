#pragma once

#include <thread>

class ThreadRaii : public std::thread {
public:
    ThreadRaii() {}

    template <typename F, typename... Args>
    ThreadRaii(F &&f, Args &&...args)
        : std::thread(std::forward<F>(f), std::forward<Args>(args)...) {}

    ~ThreadRaii() {
        this->detach();
    }
};